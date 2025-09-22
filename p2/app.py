from flask import Flask, render_template_string
import socket
import platform

app = Flask(__name__)

# Simple HTML Template
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask Status</title>
    <style>
        body {
            background-color: #000;
            color: #fff;
            font-family: 'Courier New', monospace;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        .container {
            text-align: center;
            line-height: 1.6;
        }

        .info-line {
            margin: 10px 0;
            font-size: 16px;
        }

        .label {
            color: #888;
        }

        .value {
            color: #fff;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="info-line">
            <span class="label">Hostname:</span> 
            <span class="value">{{ hostname }}</span>
        </div>
        
        <div class="info-line">
            <span class="label">IP Address:</span> 
            <span class="value">{{ ip_address }}</span>
        </div>
        
        <div class="info-line">
            <span class="label">Platform:</span> 
            <span class="value">{{ platform_info }}</span>
        </div>
    </div>
</body>
</html>
'''

@app.route("/")
def home():
    """Main route with basic system information"""
    hostname = socket.gethostname()
    
    # Get IP address
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip_address = s.getsockname()[0]
        s.close()
    except:
        ip_address = socket.gethostbyname(hostname)
    
    platform_info = f"{platform.system()} {platform.release()}"
    
    return render_template_string(HTML_TEMPLATE, 
                                hostname=hostname,
                                ip_address=ip_address,
                                platform_info=platform_info)

@app.route("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)