const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const crypto = require("crypto");

admin.initializeApp();

// Função auxiliar para gerar token seguro
function generateSecureToken(requestId) {
  const randomBytes = crypto.randomBytes(32).toString("hex");
  const hash = crypto.createHash("sha256").update(requestId + randomBytes + Date.now()).digest("hex");
  return hash;
}

// Função auxiliar para validar token
async function validateToken(requestId, token) {
  try {
    const tokenDoc = await admin.firestore()
        .collection("certification_tokens")
        .doc(requestId)
        .get();

    if (!tokenDoc.exists) {
      return false;
    }

    const tokenData = tokenDoc.data();

    // Verificar se token já foi usado
    if (tokenData.used) {
      return false;
    }

    // Verificar se token expirou (7 dias)
    const expirationDate = new Date(tokenData.createdAt.toDate());
    expirationDate.setDate(expirationDate.getDate() + 7);

    if (new Date() > expirationDate) {
      return false;
    }

    // Verificar se token corresponde
    return tokenData.token === token;
  } catch (error) {
    console.error("Erro ao validar token:", error);
    return false;
  }
}

// Função auxiliar para marcar token como usado
async function markTokenAsUsed(requestId, token) {
  await admin.firestore()
      .collection("certification_tokens")
      .doc(requestId)
      .update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
}

// Configuração do email (Gmail)
// IMPORTANTE: Configure as variáveis de ambiente no Firebase
const emailConfig = functions.config().email || {};
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: emailConfig.user || "seu-email@gmail.com",
    pass: emailConfig.password || "sua-senha-app",
  },
});

/**
 * Cloud Function: Enviar email quando nova solicitação de certificação é criada
 * Trigger: Firestore onCreate em spiritual_certifications/{requestId}
 */
exports.sendCertificationRequestEmail = functions.firestore
    .document("spiritual_certifications/{requestId}")
    .onCreate(async (snap, context) => {
      try {
        const requestData = snap.data();
        const requestId = context.params.requestId;

        console.log("📧 Nova solicitação de certificação:", requestId);

        // Gerar token seguro para aprovação/reprovação
        const token = generateSecureToken(requestId);

        // Salvar token no Firestore
        await admin.firestore()
            .collection("certification_tokens")
            .doc(requestId)
            .set({
              token: token,
              requestId: requestId,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              used: false,
            });

        // Gerar URLs de aprovação e reprovação
        const appConfig = functions.config().app || {};
        const baseUrl = appConfig.url || "https://us-central1-sinais-app.cloudfunctions.net";
        const approveUrl = `${baseUrl}/processApproval?requestId=${requestId}&token=${token}`;
        const rejectUrl = `${baseUrl}/processRejection?requestId=${requestId}&token=${token}`;

        // Email para o admin
        const adminEmail = "sinais.aplicativo@gmail.com";

        const mailOptions = {
          from: emailConfig.user || "noreply@sinais.com",
          to: adminEmail,
          subject: "🏆 Nova Solicitação de Certificação Espiritual",
          html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                border-radius: 10px 10px 0 0;
                text-align: center;
              }
              .content {
                background: #f9f9f9;
                padding: 30px;
                border-radius: 0 0 10px 10px;
              }
              .info-box {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin: 15px 0;
                border-left: 4px solid #667eea;
              }
              .label {
                font-weight: bold;
                color: #667eea;
                margin-bottom: 5px;
              }
              .value {
                color: #333;
                margin-bottom: 15px;
              }
              .button {
                display: inline-block;
                background: #667eea;
                color: white;
                padding: 12px 30px;
                text-decoration: none;
                border-radius: 5px;
                margin: 20px 0;
              }
              .footer {
                text-align: center;
                color: #666;
                font-size: 12px;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #ddd;
              }
            </style>
          </head>
          <body>
            <div class="header">
              <h1>🏆 Nova Solicitação de Certificação</h1>
              <p>Uma nova solicitação de certificação espiritual foi recebida</p>
            </div>
            
            <div class="content">
              <div class="info-box">
                <div class="label">👤 Nome do Usuário:</div>
                <div class="value">${requestData.userName || "Não informado"}</div>
                
                <div class="label">📧 Email do Usuário:</div>
                <div class="value">${requestData.userEmail || "Não informado"}</div>
                
                <div class="label">🛒 Email de Compra:</div>
                <div class="value">${requestData.purchaseEmail || "Não informado"}</div>
                
                <div class="label">📅 Data da Solicitação:</div>
                <div class="value">${requestData.createdAt ? new Date(requestData.createdAt.toDate()).toLocaleString("pt-BR") : "Não informado"}</div>
                
                <div class="label">🆔 ID da Solicitação:</div>
                <div class="value">${requestId}</div>
              </div>
              
              <div style="text-align: center;">
                <a href="${requestData.proofFileUrl || "#"}" class="button" target="_blank">
                  📄 Ver Comprovante
                </a>
              </div>
              
              <div style="margin-top: 30px; padding: 20px; background: white; border-radius: 8px; text-align: center;">
                <p style="margin-bottom: 20px; font-size: 16px; font-weight: bold; color: #333;">
                  ⚡ Ação Rápida
                </p>
                <p style="margin-bottom: 20px; color: #666;">
                  Você pode aprovar ou reprovar esta certificação diretamente deste email:
                </p>
                <div style="display: inline-block; margin: 10px;">
                  <a href="${approveUrl}" style="display: inline-block; background: #10b981; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
                    ✅ Aprovar Certificação
                  </a>
                </div>
                <div style="display: inline-block; margin: 10px;">
                  <a href="${rejectUrl}" style="display: inline-block; background: #ef4444; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
                    ❌ Reprovar Certificação
                  </a>
                </div>
                <p style="margin-top: 20px; font-size: 12px; color: #999;">
                  Os links acima são válidos por 7 dias e podem ser usados apenas uma vez.
                </p>
              </div>
              
              <p style="margin-top: 20px; padding: 15px; background: #e0f2fe; border-radius: 5px; border-left: 4px solid #0284c7; font-size: 14px;">
                <strong>💡 Dica:</strong> Você também pode acessar o painel administrativo do aplicativo para revisar esta solicitação com mais detalhes.
              </p>
            </div>
            
            <div class="footer">
              <p>Este é um email automático do sistema Sinais</p>
              <p>© ${new Date().getFullYear()} Sinais - Todos os direitos reservados</p>
            </div>
          </body>
          </html>
        `,
        };

        // Enviar email
        await transporter.sendMail(mailOptions);

        console.log("✅ Email enviado com sucesso para:", adminEmail);

        return {success: true};
      } catch (error) {
        console.error("❌ Erro ao enviar email:", error);
        // Não propagar erro para não bloquear a criação do documento
        return {success: false, error: error.message};
      }
    });

/**
 * Função auxiliar: Atualizar perfil do usuário com selo de certificação
 */
async function updateUserProfileWithCertification(userId) {
  try {
    console.log("🔄 Atualizando perfil do usuário:", userId);

    // Atualizar campo spirituallyCertified no documento do usuário
    await admin.firestore()
        .collection("usuarios")
        .doc(userId)
        .update({
          spirituallyCertified: true,
          certifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log("✅ Perfil do usuário atualizado com selo de certificação");
    return {success: true};
  } catch (error) {
    console.error("❌ Erro ao atualizar perfil do usuário:", error);
    throw error;
  }
}

/**
 * Cloud Function: Enviar email quando certificação é aprovada
 * Trigger: Firestore onUpdate em spiritual_certifications/{requestId}
 */
exports.sendCertificationApprovalEmail = functions.firestore
    .document("spiritual_certifications/{requestId}")
    .onUpdate(async (change, context) => {
      try {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // Verificar se o status mudou para 'approved'
        if (beforeData.status !== "approved" && afterData.status === "approved") {
          console.log("✅ Certificação aprovada, processando...");

          // 1. Atualizar perfil do usuário com selo de certificação
          try {
            await updateUserProfileWithCertification(afterData.userId);
          } catch (error) {
            console.error("❌ Erro ao atualizar perfil, mas continuando com email:", error);
          }

          // 2. Enviar email de aprovação
          console.log("📧 Enviando email de aprovação...");

          const mailOptions = {
            from: emailConfig.user || "noreply@sinais.com",
            to: afterData.userEmail,
            subject: "🎉 Certificação Espiritual Aprovada!",
            html: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body {
                  font-family: Arial, sans-serif;
                  line-height: 1.6;
                  color: #333;
                  max-width: 600px;
                  margin: 0 auto;
                  padding: 20px;
                }
                .header {
                  background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
                  color: white;
                  padding: 40px;
                  border-radius: 10px 10px 0 0;
                  text-align: center;
                }
                .content {
                  background: #f9f9f9;
                  padding: 30px;
                  border-radius: 0 0 10px 10px;
                }
                .success-box {
                  background: white;
                  padding: 30px;
                  border-radius: 8px;
                  text-align: center;
                  margin: 20px 0;
                  border: 2px solid #38ef7d;
                }
                .badge {
                  font-size: 80px;
                  margin: 20px 0;
                }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>🎉 Parabéns, ${afterData.userName}!</h1>
                <p>Sua certificação espiritual foi aprovada</p>
              </div>
              
              <div class="content">
                <div class="success-box">
                  <div class="badge">🏆</div>
                  <h2>Certificação Aprovada!</h2>
                  <p>Sua solicitação de certificação espiritual foi revisada e aprovada com sucesso.</p>
                  <p>Agora você possui o selo de certificação espiritual no aplicativo Sinais!</p>
                </div>
                
                <p style="text-align: center; margin-top: 30px;">
                  <strong>O que isso significa?</strong><br>
                  Seu perfil agora exibe o selo de certificação espiritual, demonstrando seu compromisso com a fé.
                </p>
              </div>
              
              <div style="text-align: center; color: #666; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
                <p>© ${new Date().getFullYear()} Sinais - Todos os direitos reservados</p>
              </div>
            </body>
            </html>
          `,
          };

          await transporter.sendMail(mailOptions);
          console.log("✅ Email de aprovação enviado para:", afterData.userEmail);
        }

        // Verificar se o status mudou para 'rejected'
        if (beforeData.status !== "rejected" && afterData.status === "rejected") {
          console.log("❌ Certificação rejeitada, enviando email...");

          const mailOptions = {
            from: emailConfig.user || "noreply@sinais.com",
            to: afterData.userEmail,
            subject: "📋 Certificação Espiritual - Revisão Necessária",
            html: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body {
                  font-family: Arial, sans-serif;
                  line-height: 1.6;
                  color: #333;
                  max-width: 600px;
                  margin: 0 auto;
                  padding: 20px;
                }
                .header {
                  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                  color: white;
                  padding: 30px;
                  border-radius: 10px 10px 0 0;
                  text-align: center;
                }
                .content {
                  background: #f9f9f9;
                  padding: 30px;
                  border-radius: 0 0 10px 10px;
                }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>📋 Revisão Necessária</h1>
                <p>Sua solicitação de certificação precisa de atenção</p>
              </div>
              
              <div class="content">
                <p>Olá, ${afterData.userName}</p>
                
                <p>Sua solicitação de certificação espiritual foi revisada e precisa de alguns ajustes.</p>
                
                ${afterData.rejectionReason ? `
                  <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f5576c;">
                    <strong>Motivo:</strong><br>
                    ${afterData.rejectionReason}
                  </div>
                ` : ""}
                
                <p>Por favor, entre em contato conosco para mais informações ou envie uma nova solicitação com as correções necessárias.</p>
              </div>
              
              <div style="text-align: center; color: #666; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
                <p>© ${new Date().getFullYear()} Sinais - Todos os direitos reservados</p>
              </div>
            </body>
            </html>
          `,
          };

          await transporter.sendMail(mailOptions);
          console.log("✅ Email de rejeição enviado para:", afterData.userEmail);
        }

        return {success: true};
      } catch (error) {
        console.error("❌ Erro ao enviar email:", error);
        return {success: false, error: error.message};
      }
    });

/**
 * Cloud Function HTTP: Processar aprovação de certificação via link do email
 * URL: /processApproval?requestId=XXX&token=YYY
 */
exports.processApproval = functions.https.onRequest(async (req, res) => {
  try {
    const {requestId, token} = req.query;

    // Validar parâmetros
    if (!requestId || !token) {
      return res.status(400).send(generateErrorPage("Parâmetros inválidos", "Link de aprovação inválido ou incompleto."));
    }

    console.log("🔍 Processando aprovação para requestId:", requestId);

    // Validar token
    const isValid = await validateToken(requestId, token);
    if (!isValid) {
      console.log("❌ Token inválido ou expirado");
      return res.status(403).send(generateErrorPage(
          "Token Inválido ou Expirado",
          "Este link de aprovação não é mais válido. O link pode ter expirado (válido por 7 dias) ou já foi usado. Por favor, acesse o painel administrativo do aplicativo para processar esta solicitação.",
      ));
    }

    // Buscar solicitação de certificação
    const certDoc = await admin.firestore()
        .collection("spiritual_certifications")
        .doc(requestId)
        .get();

    if (!certDoc.exists) {
      console.log("❌ Solicitação não encontrada");
      return res.status(404).send(generateErrorPage(
          "Solicitação Não Encontrada",
          "A solicitação de certificação não foi encontrada no sistema.",
      ));
    }

    const certData = certDoc.data();

    // Verificar se já foi processada
    if (certData.status !== "pending") {
      console.log("⚠️ Solicitação já foi processada:", certData.status);
      return res.send(generateInfoPage(
          "Solicitação Já Processada",
          `Esta solicitação já foi ${certData.status === "approved" ? "aprovada" : "reprovada"} anteriormente.`,
        certData.status === "approved" ? "success" : "warning",
      ));
    }

    // Atualizar status para aprovado
    await admin.firestore()
        .collection("spiritual_certifications")
        .doc(requestId)
        .update({
          status: "approved",
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: "email_link",
          processedVia: "email",
        });

    // Marcar token como usado
    await markTokenAsUsed(requestId, token);

    console.log("✅ Certificação aprovada com sucesso");

    // Retornar página de sucesso
    return res.send(generateSuccessPage(
        "Certificação Aprovada com Sucesso! ✅",
        `A certificação de <strong>${certData.userName}</strong> foi aprovada com sucesso.`,
        [
          "O usuário receberá uma notificação no aplicativo",
          "Um email de confirmação será enviado ao usuário",
          "O selo de certificação aparecerá automaticamente no perfil do usuário",
        ],
    ));
  } catch (error) {
    console.error("❌ Erro ao processar aprovação:", error);
    return res.status(500).send(generateErrorPage(
        "Erro ao Processar Aprovação",
        "Ocorreu um erro ao processar a aprovação. Por favor, tente novamente ou use o painel administrativo.",
    ));
  }
});

// Função auxiliar para gerar página de sucesso
function generateSuccessPage(title, message, details = []) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          overflow: hidden;
        }
        .header {
          background: linear-gradient(135deg, #10b981 0%, #059669 100%);
          color: white;
          padding: 40px 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 10px;
        }
        .content {
          padding: 40px 30px;
        }
        .message {
          font-size: 18px;
          margin-bottom: 30px;
          text-align: center;
        }
        .details {
          background: #f0fdf4;
          border-left: 4px solid #10b981;
          padding: 20px;
          border-radius: 8px;
          margin: 20px 0;
        }
        .details ul {
          margin: 10px 0;
          padding-left: 20px;
        }
        .details li {
          margin: 8px 0;
        }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 14px;
          border-top: 1px solid #e5e7eb;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="icon">✅</div>
          <h1>${title}</h1>
        </div>
        <div class="content">
          <div class="message">${message}</div>
          ${details.length > 0 ? `
            <div class="details">
              <strong>📋 Próximos Passos:</strong>
              <ul>
                ${details.map((detail) => `<li>${detail}</li>`).join("")}
              </ul>
            </div>
          ` : ""}
        </div>
        <div class="footer">
          <p>Sistema de Certificação Espiritual - Sinais</p>
          <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

// Função auxiliar para gerar página de erro
function generateErrorPage(title, message) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          overflow: hidden;
        }
        .header {
          background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
          color: white;
          padding: 40px 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 10px;
        }
        .content {
          padding: 40px 30px;
          text-align: center;
        }
        .message {
          font-size: 16px;
          margin-bottom: 20px;
        }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 14px;
          border-top: 1px solid #e5e7eb;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="icon">❌</div>
          <h1>${title}</h1>
        </div>
        <div class="content">
          <div class="message">${message}</div>
        </div>
        <div class="footer">
          <p>Sistema de Certificação Espiritual - Sinais</p>
          <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

// Função auxiliar para gerar página informativa
function generateInfoPage(title, message, type = "info") {
  const colors = {
    success: {bg: "#10b981", icon: "✅"},
    warning: {bg: "#f59e0b", icon: "⚠️"},
    info: {bg: "#3b82f6", icon: "ℹ️"},
  };

  const color = colors[type] || colors.info;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          overflow: hidden;
        }
        .header {
          background: ${color.bg};
          color: white;
          padding: 40px 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 10px;
        }
        .content {
          padding: 40px 30px;
          text-align: center;
        }
        .message {
          font-size: 16px;
        }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 14px;
          border-top: 1px solid #e5e7eb;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="icon">${color.icon}</div>
          <h1>${title}</h1>
        </div>
        <div class="content">
          <div class="message">${message}</div>
        </div>
        <div class="footer">
          <p>Sistema de Certificação Espiritual - Sinais</p>
          <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Cloud Function HTTP: Processar reprovação de certificação via link do email
 * URL: /processRejection?requestId=XXX&token=YYY
 * Método GET: Exibe formulário para inserir motivo
 * Método POST: Processa a reprovação com o motivo fornecido
 */
exports.processRejection = functions.https.onRequest(async (req, res) => {
  try {
    const {requestId, token} = req.query;

    // Validar parâmetros
    if (!requestId || !token) {
      return res.status(400).send(generateErrorPage("Parâmetros inválidos", "Link de reprovação inválido ou incompleto."));
    }

    // GET: Exibir formulário de motivo
    if (req.method === "GET") {
      console.log("📝 Exibindo formulário de reprovação para requestId:", requestId);

      // Validar token antes de exibir formulário
      const isValid = await validateToken(requestId, token);
      if (!isValid) {
        console.log("❌ Token inválido ou expirado");
        return res.status(403).send(generateErrorPage(
            "Token Inválido ou Expirado",
            "Este link de reprovação não é mais válido. O link pode ter expirado (válido por 7 dias) ou já foi usado. Por favor, acesse o painel administrativo do aplicativo para processar esta solicitação.",
        ));
      }

      // Buscar solicitação de certificação
      const certDoc = await admin.firestore()
          .collection("spiritual_certifications")
          .doc(requestId)
          .get();

      if (!certDoc.exists) {
        console.log("❌ Solicitação não encontrada");
        return res.status(404).send(generateErrorPage(
            "Solicitação Não Encontrada",
            "A solicitação de certificação não foi encontrada no sistema.",
        ));
      }

      const certData = certDoc.data();

      // Verificar se já foi processada
      if (certData.status !== "pending") {
        console.log("⚠️ Solicitação já foi processada:", certData.status);
        return res.send(generateInfoPage(
            "Solicitação Já Processada",
            `Esta solicitação já foi ${certData.status === "approved" ? "aprovada" : "reprovada"} anteriormente.`,
          certData.status === "approved" ? "success" : "warning",
        ));
      }

      // Exibir formulário de reprovação
      return res.send(generateRejectionForm(requestId, token, certData));
    }

    // POST: Processar reprovação com motivo
    if (req.method === "POST") {
      console.log("🔍 Processando reprovação para requestId:", requestId);

      // Obter motivo do corpo da requisição
      let rejectionReason = "";

      // Parse do body (pode vir como form-data ou JSON)
      if (req.body && req.body.rejectionReason) {
        rejectionReason = req.body.rejectionReason;
      } else if (req.body) {
        // Tentar parsear como string se vier como raw
        const bodyStr = req.body.toString();
        const match = bodyStr.match(/rejectionReason=([^&]*)/);
        if (match) {
          rejectionReason = decodeURIComponent(match[1].replace(/\+/g, " "));
        }
      }

      // Validar que motivo não está vazio
      if (!rejectionReason || rejectionReason.trim() === "") {
        return res.status(400).send(generateErrorPage(
            "Motivo Obrigatório",
            "Por favor, forneça um motivo para a reprovação da certificação.",
        ));
      }

      // Validar token
      const isValid = await validateToken(requestId, token);
      if (!isValid) {
        console.log("❌ Token inválido ou expirado");
        return res.status(403).send(generateErrorPage(
            "Token Inválido ou Expirado",
            "Este link de reprovação não é mais válido. O link pode ter expirado (válido por 7 dias) ou já foi usado.",
        ));
      }

      // Buscar solicitação de certificação
      const certDoc = await admin.firestore()
          .collection("spiritual_certifications")
          .doc(requestId)
          .get();

      if (!certDoc.exists) {
        console.log("❌ Solicitação não encontrada");
        return res.status(404).send(generateErrorPage(
            "Solicitação Não Encontrada",
            "A solicitação de certificação não foi encontrada no sistema.",
        ));
      }

      const certData = certDoc.data();

      // Verificar se já foi processada
      if (certData.status !== "pending") {
        console.log("⚠️ Solicitação já foi processada:", certData.status);
        return res.send(generateInfoPage(
            "Solicitação Já Processada",
            `Esta solicitação já foi ${certData.status === "approved" ? "aprovada" : "reprovada"} anteriormente.`,
          certData.status === "approved" ? "success" : "warning",
        ));
      }

      // Atualizar status para reprovado
      await admin.firestore()
          .collection("spiritual_certifications")
          .doc(requestId)
          .update({
            status: "rejected",
            rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            rejectedBy: "email_link",
            rejectionReason: rejectionReason.trim(),
            processedVia: "email",
          });

      // Marcar token como usado
      await markTokenAsUsed(requestId, token);

      console.log("✅ Certificação reprovada com sucesso");

      // Retornar página de sucesso com incentivo à mentoria
      return res.send(generateRejectionSuccessPage(certData.userName, rejectionReason));
    }

    // Método não suportado
    return res.status(405).send(generateErrorPage(
        "Método Não Permitido",
        "Este endpoint aceita apenas requisições GET e POST.",
    ));
  } catch (error) {
    console.error("❌ Erro ao processar reprovação:", error);
    return res.status(500).send(generateErrorPage(
        "Erro ao Processar Reprovação",
        "Ocorreu um erro ao processar a reprovação. Por favor, tente novamente ou use o painel administrativo.",
    ));
  }
});

// Função auxiliar para gerar formulário de reprovação
function generateRejectionForm(requestId, token, certData) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reprovar Certificação</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 700px;
          margin: 0 auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          overflow: hidden;
        }
        .header {
          background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
          color: white;
          padding: 40px 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 10px;
        }
        .content {
          padding: 40px 30px;
        }
        .user-info {
          background: #fef2f2;
          border-left: 4px solid #ef4444;
          padding: 20px;
          border-radius: 8px;
          margin-bottom: 30px;
        }
        .user-info strong {
          color: #dc2626;
        }
        .form-group {
          margin-bottom: 25px;
        }
        .form-group label {
          display: block;
          font-weight: 600;
          margin-bottom: 10px;
          color: #374151;
          font-size: 16px;
        }
        .form-group textarea {
          width: 100%;
          min-height: 150px;
          padding: 15px;
          border: 2px solid #e5e7eb;
          border-radius: 8px;
          font-family: inherit;
          font-size: 15px;
          resize: vertical;
          box-sizing: border-box;
        }
        .form-group textarea:focus {
          outline: none;
          border-color: #ef4444;
        }
        .hint {
          font-size: 14px;
          color: #6b7280;
          margin-top: 8px;
        }
        .mentorship-box {
          background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
          border: 2px solid #f59e0b;
          border-radius: 12px;
          padding: 25px;
          margin: 30px 0;
          text-align: center;
        }
        .mentorship-box h3 {
          color: #92400e;
          margin-top: 0;
          font-size: 20px;
        }
        .mentorship-box p {
          color: #78350f;
          margin: 10px 0;
          font-size: 15px;
        }
        .mentorship-benefits {
          text-align: left;
          margin: 20px auto;
          max-width: 500px;
        }
        .mentorship-benefits li {
          margin: 10px 0;
          color: #78350f;
          font-size: 14px;
        }
        .mentorship-icon {
          font-size: 48px;
          margin-bottom: 10px;
        }
        .button {
          display: inline-block;
          background: #ef4444;
          color: white;
          padding: 15px 40px;
          text-decoration: none;
          border-radius: 8px;
          font-weight: bold;
          font-size: 16px;
          border: none;
          cursor: pointer;
          transition: background 0.3s;
        }
        .button:hover {
          background: #dc2626;
        }
        .button:disabled {
          background: #9ca3af;
          cursor: not-allowed;
        }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 14px;
          border-top: 1px solid #e5e7eb;
        }
        .warning-box {
          background: #fef2f2;
          border: 1px solid #fecaca;
          border-radius: 8px;
          padding: 15px;
          margin-bottom: 20px;
        }
        .warning-box p {
          margin: 5px 0;
          color: #991b1b;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="icon">📋</div>
          <h1>Reprovar Certificação</h1>
        </div>
        
        <div class="content">
          <div class="user-info">
            <p><strong>👤 Usuário:</strong> ${certData.userName || "Não informado"}</p>
            <p><strong>📧 Email:</strong> ${certData.userEmail || "Não informado"}</p>
            <p><strong>🛒 Email de Compra:</strong> ${certData.purchaseEmail || "Não informado"}</p>
          </div>
          
          <div class="warning-box">
            <p><strong>⚠️ Atenção:</strong> Ao reprovar esta certificação, o usuário receberá uma notificação com o motivo fornecido.</p>
          </div>
          
          <form method="POST" action="/processRejection?requestId=${requestId}&token=${token}" onsubmit="return validateForm()">
            <div class="form-group">
              <label for="rejectionReason">
                Motivo da Reprovação <span style="color: #ef4444;">*</span>
              </label>
              <textarea 
                id="rejectionReason" 
                name="rejectionReason" 
                placeholder="Descreva o motivo da reprovação de forma clara e respeitosa..."
                required
              ></textarea>
              <div class="hint">
                💡 Seja específico e construtivo. Explique o que precisa ser corrigido ou verificado.
              </div>
            </div>
            
            <div class="mentorship-box">
              <div class="mentorship-icon">🎓</div>
              <h3>💡 Sugestão Especial: Mentoria Espiritual</h3>
              <p><strong>Considere recomendar nossa Mentoria Espiritual ao usuário!</strong></p>
              <p>Se o motivo da reprovação está relacionado à falta de formação espiritual adequada, nossa mentoria pode ser a solução perfeita.</p>
              
              <div class="mentorship-benefits">
                <p><strong>Benefícios da Mentoria:</strong></p>
                <ul>
                  <li>✅ Formação espiritual completa e certificada</li>
                  <li>✅ Acompanhamento personalizado por mentores experientes</li>
                  <li>✅ Conteúdo exclusivo sobre relacionamentos cristãos</li>
                  <li>✅ Comunidade de apoio e crescimento espiritual</li>
                  <li>✅ Certificação reconhecida ao final do programa</li>
                </ul>
              </div>
              
              <p style="font-size: 13px; margin-top: 15px;">
                <em>Você pode mencionar a mentoria no motivo da reprovação como uma sugestão construtiva para o usuário.</em>
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <button type="submit" class="button" id="submitBtn">
                ❌ Confirmar Reprovação
              </button>
            </div>
          </form>
        </div>
        
        <div class="footer">
          <p>Sistema de Certificação Espiritual - Sinais</p>
          <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
        </div>
      </div>
      
      <script>
        function validateForm() {
          const reason = document.getElementById('rejectionReason').value.trim();
          if (reason === '') {
            alert('Por favor, forneça um motivo para a reprovação.');
            return false;
          }
          
          // Desabilitar botão para evitar duplo envio
          const btn = document.getElementById('submitBtn');
          btn.disabled = true;
          btn.textContent = '⏳ Processando...';
          
          return true;
        }
      </script>
    </body>
    </html>
  `;
}

// Função auxiliar para gerar página de sucesso da reprovação
function generateRejectionSuccessPage(userName, rejectionReason) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Certificação Reprovada</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 700px;
          margin: 0 auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          overflow: hidden;
        }
        .header {
          background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
          color: white;
          padding: 40px 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 10px;
        }
        .content {
          padding: 40px 30px;
        }
        .success-message {
          text-align: center;
          margin-bottom: 30px;
        }
        .success-message h2 {
          color: #d97706;
          margin-bottom: 10px;
        }
        .info-box {
          background: #fef3c7;
          border-left: 4px solid #f59e0b;
          padding: 20px;
          border-radius: 8px;
          margin: 20px 0;
        }
        .info-box strong {
          color: #92400e;
        }
        .reason-box {
          background: #f9fafb;
          border: 2px solid #e5e7eb;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .reason-box h3 {
          margin-top: 0;
          color: #374151;
        }
        .reason-text {
          color: #4b5563;
          font-style: italic;
          line-height: 1.8;
        }
        .next-steps {
          background: #ecfdf5;
          border-left: 4px solid #10b981;
          padding: 20px;
          border-radius: 8px;
          margin: 30px 0;
        }
        .next-steps h3 {
          color: #065f46;
          margin-top: 0;
        }
        .next-steps ul {
          margin: 10px 0;
          padding-left: 20px;
        }
        .next-steps li {
          margin: 10px 0;
          color: #047857;
        }
        .mentorship-highlight {
          background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
          border: 3px solid #f59e0b;
          border-radius: 12px;
          padding: 30px;
          margin: 30px 0;
          text-align: center;
        }
        .mentorship-highlight h3 {
          color: #92400e;
          font-size: 22px;
          margin-top: 0;
        }
        .mentorship-highlight p {
          color: #78350f;
          font-size: 16px;
          margin: 15px 0;
        }
        .mentorship-icon-large {
          font-size: 72px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 14px;
          border-top: 1px solid #e5e7eb;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="icon">✅</div>
          <h1>Reprovação Processada</h1>
        </div>
        
        <div class="content">
          <div class="success-message">
            <h2>Certificação Reprovada com Sucesso</h2>
            <p>A certificação de <strong>${userName}</strong> foi reprovada e o usuário será notificado.</p>
          </div>
          
          <div class="reason-box">
            <h3>📝 Motivo Fornecido:</h3>
            <p class="reason-text">"${rejectionReason}"</p>
          </div>
          
          <div class="info-box">
            <p><strong>📋 O que acontece agora:</strong></p>
            <ul>
              <li>O usuário receberá uma notificação no aplicativo com o motivo da reprovação</li>
              <li>Um email será enviado ao usuário explicando a situação</li>
              <li>O usuário poderá enviar uma nova solicitação após corrigir os pontos mencionados</li>
            </ul>
          </div>
          
          <div class="mentorship-highlight">
            <div class="mentorship-icon-large">🎓</div>
            <h3>💡 Lembre-se da Mentoria Espiritual!</h3>
            <p><strong>Se o usuário precisar de formação espiritual mais aprofundada, nossa Mentoria Espiritual é a solução ideal.</strong></p>
            <p>Considere entrar em contato com o usuário para oferecer informações sobre o programa de mentoria, que pode ajudá-lo a obter a certificação no futuro.</p>
            <p style="font-size: 14px; margin-top: 20px;">
              <em>A mentoria oferece formação completa, acompanhamento personalizado e certificação reconhecida.</em>
            </p>
          </div>
          
          <div class="next-steps">
            <h3>✅ Próximos Passos Recomendados:</h3>
            <ul>
              <li>Verifique se o email de notificação foi enviado ao usuário</li>
              <li>Considere entrar em contato pessoalmente para oferecer suporte</li>
              <li>Se apropriado, compartilhe informações sobre a Mentoria Espiritual</li>
              <li>Mantenha o registro desta ação no histórico do painel administrativo</li>
            </ul>
          </div>
        </div>
        
        <div class="footer">
          <p>Sistema de Certificação Espiritual - Sinais</p>
          <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Cloud Function Trigger: Detectar mudanças de status de certificação
 * Trigger: Firestore onUpdate em spiritual_certifications/{requestId}
 *
 * Quando o status muda de 'pending' para 'approved' ou 'rejected':
 * 1. Cria notificação para o usuário
 * 2. Atualiza perfil do usuário (se aprovado)
 * 3. Envia email de confirmação ao admin
 * 4. Registra log de auditoria
 */
exports.onCertificationStatusChange = functions.firestore
    .document("spiritual_certifications/{requestId}")
    .onUpdate(async (change, context) => {
      try {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const requestId = context.params.requestId;

        console.log("🔄 Detectada mudança em certificação:", requestId);
        console.log("Status anterior:", beforeData.status);
        console.log("Status novo:", afterData.status);

        // Só processar se o status mudou de 'pending' para outro status
        if (beforeData.status === "pending" && afterData.status !== "pending") {
          console.log("✅ Processando mudança de status de pending para", afterData.status);

          const {userId, status, rejectionReason, userName, userEmail} = afterData;

          // 1. Criar notificação para o usuário
          await createUserNotification(userId, status, rejectionReason, userName);

          // 2. Atualizar perfil do usuário se aprovado
          if (status === "approved") {
            await updateUserProfile(userId);
          }

          // 3. Enviar email de confirmação ao admin
          await sendAdminConfirmationEmail(afterData, requestId);

          // 4. Registrar log de auditoria
          await logAuditTrail(requestId, afterData);

          console.log("✅ Todas as ações pós-mudança de status foram executadas com sucesso");
        } else {
          console.log("ℹ️ Mudança de status não requer processamento (não era pending)");
        }

        return {success: true};
      } catch (error) {
        console.error("❌ Erro ao processar mudança de status:", error);
        // Não propagar erro para não bloquear a atualização do documento
        return {success: false, error: error.message};
      }
    });

/**
 * Função auxiliar: Criar notificação para o usuário
 */
async function createUserNotification(userId, status, rejectionReason, userName) {
  try {
    console.log("📬 Criando notificação para usuário:", userId);

    const notificationData = {
      userId: userId,
      type: status === "approved" ? "certification_approved" : "certification_rejected",
      title: status === "approved" ?
        "🎉 Certificação Aprovada!" :
        "📋 Certificação Não Aprovada",
      message: status === "approved" ?
        "Parabéns! Sua certificação espiritual foi aprovada. O selo já está visível no seu perfil." :
        `Sua solicitação de certificação não foi aprovada. Motivo: ${rejectionReason || "Não especificado"}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      actionType: status === "approved" ? "view_profile" : "retry_certification",
      metadata: {
        certificationStatus: status,
        rejectionReason: rejectionReason || null,
      },
    };

    await admin.firestore()
        .collection("notifications")
        .add(notificationData);

    console.log("✅ Notificação criada com sucesso para:", userName);
  } catch (error) {
    console.error("❌ Erro ao criar notificação:", error);
    throw error;
  }
}

/**
 * Função auxiliar: Atualizar perfil do usuário com selo de certificação
 */
async function updateUserProfile(userId) {
  try {
    console.log("👤 Atualizando perfil do usuário:", userId);

    await admin.firestore()
        .collection("users")
        .doc(userId)
        .update({
          spirituallyCertified: true,
          certifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log("✅ Perfil atualizado com selo de certificação");
  } catch (error) {
    console.error("❌ Erro ao atualizar perfil:", error);
    throw error;
  }
}

/**
 * Função auxiliar: Enviar email de confirmação ao admin
 */
async function sendAdminConfirmationEmail(certData, requestId) {
  try {
    console.log("📧 Enviando email de confirmação ao admin");

    const adminEmail = "sinais.aplicativo@gmail.com";
    const {status, userName, userEmail, approvedBy, rejectedBy, rejectionReason, processedVia} = certData;

    const isApproved = status === "approved";
    const processedByInfo = isApproved ? approvedBy : rejectedBy;
    const processMethod = processedVia === "email" ? "via link do email" : "via painel administrativo";

    const mailOptions = {
      from: emailConfig.user || "noreply@sinais.com",
      to: adminEmail,
      subject: isApproved ?
        "✅ Certificação Aprovada - Confirmação" :
        "❌ Certificação Reprovada - Confirmação",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Confirmação de Processamento</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              line-height: 1.6;
              color: #333;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
              background: #f5f5f5;
            }
            .container {
              background: white;
              border-radius: 12px;
              box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              overflow: hidden;
            }
            .header {
              background: ${isApproved ? "linear-gradient(135deg, #10b981 0%, #059669 100%)" : "linear-gradient(135deg, #f59e0b 0%, #d97706 100%)"};
              color: white;
              padding: 30px;
              text-align: center;
            }
            .header h1 {
              margin: 0;
              font-size: 24px;
            }
            .icon {
              font-size: 48px;
              margin-bottom: 10px;
            }
            .content {
              padding: 30px;
            }
            .info-box {
              background: #f9fafb;
              border-left: 4px solid ${isApproved ? "#10b981" : "#f59e0b"};
              padding: 15px;
              border-radius: 8px;
              margin: 15px 0;
            }
            .info-row {
              margin: 8px 0;
            }
            .label {
              font-weight: bold;
              color: #374151;
            }
            .value {
              color: #6b7280;
            }
            .footer {
              text-align: center;
              padding: 20px;
              color: #666;
              font-size: 14px;
              border-top: 1px solid #e5e7eb;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="icon">${isApproved ? "✅" : "⚠️"}</div>
              <h1>Certificação ${isApproved ? "Aprovada" : "Reprovada"}</h1>
              <p>Confirmação de Processamento</p>
            </div>
            
            <div class="content">
              <p>Uma certificação foi processada com sucesso:</p>
              
              <div class="info-box">
                <div class="info-row">
                  <span class="label">👤 Usuário:</span>
                  <span class="value">${userName}</span>
                </div>
                <div class="info-row">
                  <span class="label">📧 Email:</span>
                  <span class="value">${userEmail}</span>
                </div>
                <div class="info-row">
                  <span class="label">📋 Status:</span>
                  <span class="value">${isApproved ? "Aprovada ✅" : "Reprovada ❌"}</span>
                </div>
                <div class="info-row">
                  <span class="label">🔧 Processado por:</span>
                  <span class="value">${processedByInfo}</span>
                </div>
                <div class="info-row">
                  <span class="label">📍 Método:</span>
                  <span class="value">${processMethod}</span>
                </div>
                ${!isApproved && rejectionReason ? `
                  <div class="info-row" style="margin-top: 15px; padding-top: 15px; border-top: 1px solid #e5e7eb;">
                    <span class="label">💬 Motivo da Reprovação:</span><br>
                    <span class="value" style="font-style: italic;">"${rejectionReason}"</span>
                  </div>
                ` : ""}
              </div>
              
              <div style="background: ${isApproved ? "#ecfdf5" : "#fef3c7"}; border-left: 4px solid ${isApproved ? "#10b981" : "#f59e0b"}; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0;"><strong>📋 Ações Executadas:</strong></p>
                <ul style="margin: 10px 0; padding-left: 20px;">
                  <li>Notificação criada para o usuário</li>
                  ${isApproved ? "<li>Selo de certificação adicionado ao perfil</li>" : ""}
                  <li>Email de ${isApproved ? "aprovação" : "reprovação"} enviado ao usuário</li>
                  <li>Log de auditoria registrado</li>
                </ul>
              </div>
              
              <p style="text-align: center; margin-top: 20px;">
                <a href="https://console.firebase.google.com/project/sinais-app/firestore/data/~2Fspiritual_certifications~2F${requestId}" 
                   style="display: inline-block; background: #667eea; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">
                  Ver no Firebase Console
                </a>
              </p>
            </div>
            
            <div class="footer">
              <p>Sistema de Certificação Espiritual - Sinais</p>
              <p>© ${new Date().getFullYear()} Todos os direitos reservados</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Email de confirmação enviado ao admin");
  } catch (error) {
    console.error("❌ Erro ao enviar email de confirmação:", error);
    // Não propagar erro - email de confirmação é opcional
  }
}

/**
 * Função auxiliar: Registrar log de auditoria
 */
async function logAuditTrail(requestId, certData) {
  try {
    console.log("📝 Registrando log de auditoria");

    const {status, userId, userName, approvedBy, rejectedBy, rejectionReason, processedVia} = certData;

    const auditData = {
      requestId: requestId,
      userId: userId,
      userName: userName,
      action: status === "approved" ? "certification_approved" : "certification_rejected",
      performedBy: status === "approved" ? approvedBy : rejectedBy,
      processedVia: processedVia,
      rejectionReason: rejectionReason || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        status: status,
        ipAddress: null, // Pode ser adicionado se disponível
        userAgent: null, // Pode ser adicionado se disponível
      },
    };

    await admin.firestore()
        .collection("certification_audit_log")
        .add(auditData);

    console.log("✅ Log de auditoria registrado com sucesso");
  } catch (error) {
    console.error("❌ Erro ao registrar log de auditoria:", error);
    // Não propagar erro - log é importante mas não crítico
  }
}
