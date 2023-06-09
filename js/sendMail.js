"use strict";
const nodemailer = require("nodemailer");

let host = process.env.mail_server;
let port = process.env.mail_port;
let sender = process.env.mail_sender;
let receiver = process.env.mail_receiver;
let pass = process.env.mail_pass;
let subject = process.env.mail_subject;
let body = process.env.mail_body;
let bodyFile = process.env.mail_body_file;

if (!host) {
    host = "smtp." + sender.split("@")[1];
}

if (!port) {
    port = 465;
}

if (!subject) {
    subject = "Hello There!"
}
let now = (new Date()).toISOString();
console.log("now is %s", now);
subject = subject + " " + now;

if (!bodyFile && !body) {
    body = "<b>It's an empty mail.</b>";
} 

async function main() {
    console.log("send from %s, to %s", sender, receiver);

    if(bodyFile){
        const { readFile } = require('fs/promises')    
        body = await readFile(bodyFile, 'utf8')
        
        console.log("total report size: %s", body.length);
    }

    let transporter = nodemailer.createTransport({
        host: host,
        port: port,
        secure: true,
        auth: {
            user: sender,
            pass: pass,
        },
    });

    let info = await transporter.sendMail({
        from: sender,
        to: receiver,
        subject: subject,
        text: "Hello world!",
        html: body,
    });

    console.log("Message sent: %s", info.messageId);
}

main()