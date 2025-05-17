from flask import Flask, request, jsonify, render_template_string
from flask_mail import Mail, Message
import subprocess
import threading
import os
import logging
from logging.handlers import RotatingFileHandler

app = Flask(__name__)

# Configure Gmail SMTP
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'chandanpradhan092@gmail.com'
app.config['MAIL_PASSWORD'] = 'fkao giub tcfn jszf'
app.config['MAIL_DEFAULT_SENDER'] = ('Build System', 'chandanpradhan092@gmail.com')

mail = Mail(app)

# Configure logging
if not os.path.exists('logs'):
    os.mkdir('logs')
file_handler = RotatingFileHandler('logs/app_log', maxBytes=10240, backupCount=10)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.INFO)
app.logger.info('Application startup')

# State dictionary to track builds
builds = {}

# Recipients
recipients_to = ['chandanpradhan092@gmail.com', 'sunil.bhuyan@genbridgelabs.in', 'sangram.pradhan.keshari@gmail.com']
cc_list = ['plaban.padhi@gmail.com', 'genbridgelabs@gmail.com', 'amareshpr.2022@gmail.com']

def generate_approval_email(project_name, git_url):
    return f"""
    <html>
    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
        <div style="max-width: 600px; margin: auto; background-color: #ffffff; padding: 20px; border-radius: 5px;">
            <h2 style="color: #333333;">Build Approval Request</h2>
            <p>Dear Team,</p>
            <p>Please review and approve the build for the project:</p>
            <ul>
                <li><strong>Project Name:</strong> {project_name}</li>
                <li><strong>Git URL:</strong> {git_url}</li>
            </ul>
            <p>To approve this build, click the button below:</p>
            <p>
                <a href="http://127.0.0.1:5000/approve?project_name={project_name}&git_url={git_url}" target="_blank" style="background-color: #28a745; color: white; padding: 10px 15px; text-decoration: none; border-radius: 5px;">Approve Build</a>
            </p>
            <p>Best regards,<br/>Build System</p>
        </div>
    </body>
    </html>
    """

def generate_deployment_email(project_name, git_url):
    return f"""
    <html>
    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
        <div style="max-width: 600px; margin: auto; background-color: #ffffff; padding: 20px; border-radius: 5px;">
            <h2 style="color: #333333;">Build Deployed Successfully</h2>
            <p>The build for the project has been deployed successfully:</p>
            <ul>
                <li><strong>Project Name:</strong> {project_name}</li>
                <li><strong>Git URL:</strong> {git_url}</li>
            </ul>
            <p>Best regards,<br/>Build System</p>
        </div>
    </body>
    </html>
    """

@app.route('/deploy', methods=['POST'])
def send_mail():
    data = request.get_json()
    project_name = data.get('project_name')
    git_url = data.get('git_url')

    if not project_name or not git_url:
        app.logger.warning("Missing project_name or git_url in deployment request.")
        return jsonify({"error": "project_name and git_url are required"}), 400

    build_key = f"{project_name}|{git_url}"
    builds[build_key] = {
        "approved": False,
        "deployed": False
    }

    subject = f"Approval Request for Build: {project_name}"
    html_body = generate_approval_email(project_name, git_url)

    msg = Message(subject, recipients=recipients_to, cc=cc_list)
    msg.html = html_body

    try:
        mail.send(msg)
        app.logger.info(f"Approval email sent for project '{project_name}'.")
        return jsonify({"message": f"Approval email sent for project '{project_name}'."}), 200
    except Exception as e:
        app.logger.error(f"Failed to send approval email for project '{project_name}': {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/approve', methods=['GET'])
def approve():
    project_name = request.args.get('project_name')
    git_url = request.args.get('git_url')

    if not project_name or not git_url:
        return render_template_string("""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Missing Parameters</title>
            <style>
                body { font-family: Arial, sans-serif; background-color: #f8d7da; color: #721c24; padding: 20px; }
                .container { max-width: 600px; margin: auto; background-color: #f5c6cb; padding: 20px; border-radius: 5px; }
                h2 { text-align: center; }
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Error: Missing Parameters</h2>
                <p>Both <strong>project_name</strong> and <strong>git_url</strong> are required.</p>
            </div>
        </body>
        </html>
        """), 400

    build_key = f"{project_name}|{git_url}"
    build_status = builds.get(build_key)

    if not build_status:
        return render_template_string("""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Build Not Found</title>
            <style>
                body { font-family: Arial, sans-serif; background-color: #fff3cd; color: #856404; padding: 20px; }
                .container { max-width: 600px; margin: auto; background-color: #ffeeba; padding: 20px; border-radius: 5px; }
                h2 { text-align: center; }
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Build Not Found</h2>
                <p>The specified build was not found. Please initiate the approval process first.</p>
            </div>
        </body>
        </html>
        """), 404

    if build_status["deployed"]:
        return render_template_string(f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Build Already Deployed</title>
            <style>
                body {{ font-family: Arial, sans-serif; background-color: #d4edda; color: #155724; padding: 20px; }}
                .container {{ max-width: 600px; margin: auto; background-color: #c3e6cb; padding: 20px; border-radius: 5px; }}
                h2 {{ text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Build Already Deployed</h2>
                <p>The build for project <strong>{project_name}</strong> has already been deployed.</p>
            </div>
        </body>
        </html>
        """), 200

    if build_status["approved"]:
        return render_template_string(f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Build Already Approved</title>
            <style>
                body {{ font-family: Arial, sans-serif; background-color: #fff3cd; color: #856404; padding: 20px; }}
                .container {{ max-width: 600px; margin: auto; background-color: #ffeeba; padding: 20px; border-radius: 5px; }}
                h2 {{ text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Build Already Approved</h2>
                <p>The build for project <strong>{project_name}</strong> has already been approved and is pending deployment.</p>
            </div>
        </body>
        </html>
        """), 200

    # Mark as approved
    build_status["approved"] = True

    def deploy_and_notify():
        with app.app_context():
            try:
                subprocess.run(["/home/script/deploy_project.sh", project_name, git_url], check=True)
                build_status["deployed"] = True
                subject = f"Build Deployed: {project_name}"
                html_body = generate_deployment_email(project_name, git_url)
        
                msg = Message(subject, recipients=recipients_to, cc=cc_list)
                msg.html = html_body
                mail.send(msg)
            except subprocess.CalledProcessError as e:
                app.logger.error(f"Deployment script failed for {build_key}: {e}")
                subject = f"Deployment Failed: {project_name}"
                html_body = f"""
                <html>
                <body style="font-family: Arial, sans-serif; background-color: #f8d7da; padding: 20px;">
                    <div style="max-width: 600px; margin: auto; background-color: #f5c6cb; padding: 20px; border-radius: 5px;">
                        <h2 style="color: #721c24;">Deployment Failed</h2>
                        <p>The deployment for the project <strong>{project_name}</strong> has failed.</p>
                        <p><strong>Error Details:</strong></p>
                        <pre>{str(e)}</pre>
                        <p>Please check the deployment script and try again.</p>
                    </div>
                </body>
                </html>
                """
        
                msg = Message(subject, recipients=recipients_to, cc=cc_list)
                msg.html = html_body
                mail.send(msg)

    threading.Thread(target=deploy_and_notify).start()

    return render_template_string(f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Build Approved</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                background-color: #e2f0d9;
                color: #155724;
                padding: 20px;
            }}
            .container {{
                max-width: 600px;
                margin: auto;
                background-color: #d4edda;
                padding: 20px;
                border-radius: 5px;
                box-shadow: 0 0 10px rgba(0,0,0,0.1);
                animation: fadeIn 1s ease-in-out;
            }}
            h2 {{
                text-align: center;
                margin-bottom: 20px;
            }}
            p {{
                font-size: 1.1em;
                text-align: center;
            }}
            @keyframes fadeIn {{
                from {{ opacity: 0; }}
                to {{ opacity: 1; }}
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Build Approved</h2>
            <p>The build for project <strong>{project_name}</strong> has been approved. Deployment has been initiated.</p>
        </div>
    </body>
    </html>
    """), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)