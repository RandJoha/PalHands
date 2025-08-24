const nodemailer = require('nodemailer');

let transporter = null;

function getTransporter() {
	if (transporter) return transporter;

	// Support both SMTP_* and EMAIL_* environment variable names
	const host = process.env.SMTP_HOST || process.env.EMAIL_HOST;
	const port = Number(process.env.SMTP_PORT || process.env.EMAIL_PORT);
	const user = process.env.SMTP_USER || process.env.EMAIL_USER;
	const pass = process.env.SMTP_PASS || process.env.EMAIL_PASS;
	const secure = String(process.env.SMTP_SECURE ?? process.env.EMAIL_SECURE ?? 'false')
		.toLowerCase() === 'true';

	if (host && port && user && pass) {
		transporter = nodemailer.createTransport({
			host,
			port,
			secure,
			auth: { user, pass },
		});
	} else {
		// Dev fallback: log emails to console so developers can copy test tokens/links
		transporter = {
			sendMail: async (opts) => {
				console.log('[DEV MAILER] No SMTP configured. Logging email to console.');
				console.log('[DEV MAILER] To:', opts.to);
				console.log('[DEV MAILER] Subject:', opts.subject);
				console.log('[DEV MAILER] Text:', opts.text);
				console.log('[DEV MAILER] HTML:', opts.html);
				return { messageId: 'dev-' + Date.now() };
			},
		};
	}
	return transporter;
}

async function sendEmail({ to, subject, text, html }) {
	const from = process.env.SMTP_FROM || process.env.EMAIL_FROM || 'no-reply@palhands.local';
	const tx = getTransporter();
	return tx.sendMail({ from, to, subject, text, html });
}

module.exports = { sendEmail };
