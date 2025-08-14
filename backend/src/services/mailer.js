const nodemailer = require('nodemailer');

let transporter = null;

function getTransporter() {
	if (transporter) return transporter;
	const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_SECURE } = process.env;
	if (SMTP_HOST && SMTP_PORT && SMTP_USER && SMTP_PASS) {
		transporter = nodemailer.createTransport({
			host: SMTP_HOST,
			port: Number(SMTP_PORT),
			secure: String(SMTP_SECURE || 'false').toLowerCase() === 'true',
			auth: { user: SMTP_USER, pass: SMTP_PASS }
		});
	} else {
		transporter = {
			sendMail: async (opts) => {
				// Dev fallback: log to console
				console.log('[DEV MAILER] To:', opts.to);
				console.log('[DEV MAILER] Subject:', opts.subject);
				console.log('[DEV MAILER] Text:', opts.text);
				console.log('[DEV MAILER] HTML:', opts.html);
				return { messageId: 'dev-' + Date.now() };
			}
		};
	}
	return transporter;
}

async function sendEmail({ to, subject, text, html }) {
	const from = process.env.SMTP_FROM || 'no-reply@palhands.local';
	const tx = getTransporter();
	return tx.sendMail({ from, to, subject, text, html });
}

module.exports = { sendEmail };
