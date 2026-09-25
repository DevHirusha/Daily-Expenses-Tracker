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

    public void sendResetOtpEmail(String toEmail, String otp) {

        try {

            MimeMessage message = mailSender.createMimeMessage();

            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Password Reset OTP - PocketCrew");

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
                                Password Reset Request
                            </h2>

                            <p style="
                                font-size:15px;
                                line-height:1.7;
                                color:#555555;
                            ">
                                We received a request to reset the password
                                for your <strong>PocketCrew</strong> account.
                            </p>

                            <p style="
                                font-size:15px;
                                line-height:1.7;
                                color:#555555;
                            ">
                                Please use the verification code below to
                                continue resetting your password.
                            </p>


                            <!-- OTP Box -->
                            <div style="
                                text-align:center;
                                margin:30px 0;
                            ">

                                <div style="
                                    display:inline-block;
                                    padding:18px 35px;
                                    background:#fff4ef;
                                    border:2px solid #ff8a50;
                                    border-radius:10px;
                                ">

                                    <span style="
                                        display:block;
                                        font-size:12px;
                                        color:#777777;
                                        margin-bottom:8px;
                                        text-transform:uppercase;
                                        letter-spacing:1px;
                                    ">
                                        Your OTP Code
                                    </span>

                                    <strong style="
                                        font-size:32px;
                                        letter-spacing:8px;
                                        color:#040063;
                                    ">
                                        %s
                                    </strong>

                                </div>

                            </div>


                            <!-- Expiry Warning -->
                            <div style="
                                background:#f8fafa;
                                border-left:4px solid #ff8a50;
                                padding:15px;
                                margin:20px 0;
                            ">

                                <strong>
                                    OTP Expiration
                                </strong>

                                <br>

                                <span style="
                                    color:#666666;
                                    line-height:1.6;
                                ">
                                    This OTP is valid for
                                    <strong>10 minutes</strong>.
                                    Please complete the password reset
                                    before it expires.
                                </span>

                            </div>


                            <!-- Security Notice -->
                            <div style="
                                background:#f8fafa;
                                padding:15px;
                                margin:20px 0;
                                border-radius:7px;
                            ">

                                <strong style="color:#040063;">
                                    Security Notice
                                </strong>

                                <br>

                                <span style="
                                    color:#666666;
                                    line-height:1.6;
                                ">
                                    If you did not request a password reset,
                                    please ignore this email.
                                    Never share this OTP with anyone.
                                </span>

                            </div>


                            <p style="
                                font-size:14px;
                                line-height:1.7;
                                color:#555555;
                                margin-top:30px;
                            ">
                                For your security, our team will never ask
                                you to share your OTP or password.
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
                """.formatted(otp);

            helper.setText(htmlContent, true);

            // Send email
            mailSender.send(message);

        } catch (MessagingException e) {

            throw new RuntimeException(
                    "Failed to send password reset OTP. Please try again later.",
                    e
            );
        }
    }

    public void sendOtpEmail(String toEmail, String otp) {

        try {

            MimeMessage message = mailSender.createMimeMessage();

            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Verify Your Email - PocketCrew");

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
                            Verify Your Email Address
                        </h2>

                        <p style="
                            font-size:15px;
                            line-height:1.7;
                            color:#555555;
                        ">
                            Welcome to <strong>PocketCrew</strong>!
                            Please verify your email address to complete
                            your account registration.
                        </p>

                        <p style="
                            font-size:15px;
                            line-height:1.7;
                            color:#555555;
                        ">
                            Use the verification code below to verify
                            your email address and activate your account.
                        </p>


                        <!-- OTP Box -->
                        <div style="
                            text-align:center;
                            margin:30px 0;
                        ">

                            <div style="
                                display:inline-block;
                                padding:18px 35px;
                                background:#fff4ef;
                                border:2px solid #ff8a50;
                                border-radius:10px;
                            ">

                                <span style="
                                    display:block;
                                    font-size:12px;
                                    color:#777777;
                                    margin-bottom:8px;
                                    text-transform:uppercase;
                                    letter-spacing:1px;
                                ">
                                    Your Verification Code
                                </span>

                                <strong style="
                                    font-size:32px;
                                    letter-spacing:8px;
                                    color:#040063;
                                ">
                                    %s
                                </strong>

                            </div>

                        </div>


                        <!-- Expiry Warning -->
                        <div style="
                            background:#f8fafa;
                            border-left:4px solid #ff8a50;
                            padding:15px;
                            margin:20px 0;
                        ">

                            <strong>
                                OTP Expiration
                            </strong>

                            <br>

                            <span style="
                                color:#666666;
                                line-height:1.6;
                            ">
                                This verification code is valid for
                                <strong>24 hours</strong>.
                                Please verify your email before it expires.
                            </span>

                        </div>


                        <!-- Security Notice -->
                        <div style="
                            background:#f8fafa;
                            padding:15px;
                            margin:20px 0;
                            border-radius:7px;
                        ">

                            <strong style="color:#040063;">
                                Security Notice
                            </strong>

                            <br>

                            <span style="
                                color:#666666;
                                line-height:1.6;
                            ">
                                If you did not create a PocketCrew account,
                                please ignore this email.
                                Never share this verification code with anyone.
                            </span>

                        </div>


                        <p style="
                            font-size:14px;
                            line-height:1.7;
                            color:#555555;
                            margin-top:30px;
                        ">
                            For your security, our team will never ask
                            you to share your OTP or password.
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
            """.formatted(otp);

            helper.setText(htmlContent, true);

            // Send email
            mailSender.send(message);

        } catch (MessagingException e) {

            throw new RuntimeException(
                    "Failed to send verification OTP. Please try again later.",
                    e
            );
        }
    }

}