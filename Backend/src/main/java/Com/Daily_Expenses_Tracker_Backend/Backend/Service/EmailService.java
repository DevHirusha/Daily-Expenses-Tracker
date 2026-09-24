package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.properties.mail.smtp.from}")
    private String fromEmail;

    public void sendWelcomeEmail(String toEmail, String name) {

        try {

            MimeMessage message = mailSender.createMimeMessage();

            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Welcome to Daily Expenses Tracker");

            String htmlContent = """
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport"
                              content="width=device-width, initial-scale=1.0">
                    </head>

                    <body style="
                        margin:0;
                        padding:0;
                        background-color:#040063;
                        font-family:Arial, Helvetica, sans-serif;
                    ">

                        <div style="
                            max-width:600px;
                            margin:40px auto;
                            background:#ffffff;
                            border-radius:12px;
                            overflow:hidden;
                        ">

                            <!-- Header -->
                            <div style="
                                background:#040063;
                                padding:30px;
                                text-align:center;
                                color:white;
                            ">

                                <h1 style="
                                    margin:0;
                                    font-size:28px;
                                ">
                                    PocketCrew
                                </h1>

                                <p style="
                                    margin:10px 0 0;
                                    font-size:14px;
                                    color:white;
                                ">
                                    Take control of your daily spending
                                </p>

                            </div>


                            <!-- Content -->
                            <div style="
                                padding:35px;
                                color:#333333;
                            ">

                                <h2 style="
                                    color:#ff8a50;
                                    margin-top:0;
                                ">
                                    Welcome, %s! 👋
                                </h2>

                                <p style="
                                    font-size:15px;
                                    line-height:1.7;
                                    color:#555555;
                                ">
                                    Thank you for joining
                                    <strong>Daily Expenses Tracker</strong>.
                                    We're excited to have you with us!
                                </p>

                                <p style="
                                    font-size:15px;
                                    line-height:1.7;
                                    color:#555555;
                                ">
                                    Your account has been successfully created.
                                    You can now record, organize and monitor
                                    your daily expenses in one place.
                                </p>


                                <!-- Features -->
                                <div style="
                                    background:#f8fafa;
                                    border-left:4px solid #ff8a50;
                                    padding:15px;
                                    margin:20px 0;
                                ">
                                    <strong> Track Your Expenses</strong>
                                    <br>
                                    <span style="color:#666666;">
                                        Record your daily spending easily.
                                    </span>
                                </div>


                                <div style="
                                    background:#f8fafa;
                                    border-left:4px solid #ff8a50;
                                    padding:15px;
                                    margin:20px 0;
                                ">
                                    <strong> Monitor Your Spending</strong>
                                    <br>
                                    <span style="color:#666666;">
                                        Understand where your money goes.
                                    </span>
                                </div>


                                <div style="
                                    background:#f8fafa;
                                    border-left:4px solid #ff8a50;
                                    padding:15px;
                                    margin:20px 0;
                                ">
                                    <strong> Manage Your Budget</strong>
                                    <br>
                                    <span style="color:#666666;">
                                        Build better financial habits.
                                    </span>
                                </div>


                                <!-- Button -->
                                <div style="
                                    text-align:center;
                                    margin:30px 0;
                                ">

                                    <a href="http://localhost:5173"
                                       style="
                                       display:inline-block;
                                       padding:14px 28px;
                                       background:#ff8a50;
                                       color:#ffffff;
                                       text-decoration:none;
                                       border-radius:7px;
                                       font-weight:bold;
                                       ">
                                        Get Started
                                    </a>

                                </div>


                                <p style="
                                    font-size:14px;
                                    line-height:1.7;
                                    color:#555555;
                                ">
                                    Start by adding your first expense and
                                    take the first step toward better
                                    financial management.
                                </p>


                                <p style="
                                    font-size:14px;
                                    line-height:1.7;
                                    color:#555555;
                                ">
                                    Best regards,<br>
                                    <strong>
                                        PocketCrew Security Team
                                    </strong>
                                </p>

                            </div>


                            <!-- Footer -->
                            <div style="
                                background:#f4f7f6;
                                padding:20px;
                                text-align:center;
                                font-size:12px;
                                color:#888888;
                            ">

                                © 2026 PocketCrew.
                                All rights reserved.

                                <br><br>

                                This is an automated email.
                                Please do not reply directly.

                            </div>

                        </div>

                    </body>
                    </html>
                    """.formatted(name);

            helper.setText(htmlContent, true);

            // Send email
            mailSender.send(message);

        } catch (MessagingException e) {

            throw new RuntimeException(
                    "Failed to send welcome email",
                    e);
        }
    }
}