from flask import Flask, render_template_string
import socket

app = Flask(__name__)

# HTML Template with Rainbow Cat Progress Bar
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ hostname }}</title>
    <style>
        body {
            background-color: #000;
            color: #fff;
            font-family: 'Courier New', monospace;
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        .hostname {
            font-size: 3rem;
            font-weight: bold;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
            margin-bottom: 50px;
        }

        .progress-container {
            width: 400px;
            height: 20px;
            background-color: #333;
            border-radius: 10px;
            overflow: hidden;
            position: relative;
            border: 2px solid #555;
        }

        .progress-bar {
            height: 100%;
            width: 0%;
            background: linear-gradient(90deg, 
                #ff0000, #ff8000, #ffff00, #80ff00, 
                #00ff00, #00ff80, #00ffff, #0080ff, 
                #0000ff, #8000ff, #ff00ff, #ff0080);
            background-size: 200% 100%;
            animation: progress-fill 3s ease-in-out infinite,
                       rainbow-shift 2s linear infinite;
            border-radius: 8px;
        }

        .nyan-cat {
            position: absolute;
            right: -30px;
            top: -15px;
            font-size: 2rem;
            animation: cat-bounce 0.5s ease-in-out infinite alternate;
        }

        @keyframes progress-fill {
            0% { width: 0%; }
            50% { width: 100%; }
            100% { width: 0%; }
        }

        @keyframes rainbow-shift {
            0% { background-position: 0% 50%; }
            100% { background-position: 200% 50%; }
        }

        @keyframes cat-bounce {
            0% { transform: translateY(0px); }
            100% { transform: translateY(-5px); }
        }

        .sparkles {
            position: absolute;
            width: 100%;
            height: 100%;
            pointer-events: none;
        }

        .sparkle {
            position: absolute;
            color: #fff;
            font-size: 12px;
            animation: sparkle 1.5s linear infinite;
        }

        @keyframes sparkle {
            0% { opacity: 0; transform: translateY(0) scale(0); }
            50% { opacity: 1; transform: translateY(-20px) scale(1); }
            100% { opacity: 0; transform: translateY(-40px) scale(0); }
        }

        .sparkle:nth-child(1) { left: 10%; animation-delay: 0s; }
        .sparkle:nth-child(2) { left: 30%; animation-delay: 0.3s; }
        .sparkle:nth-child(3) { left: 50%; animation-delay: 0.6s; }
        .sparkle:nth-child(4) { left: 70%; animation-delay: 0.9s; }
        .sparkle:nth-child(5) { left: 90%; animation-delay: 1.2s; }
    </style>
</head>
<body>
    <div class="hostname">{{ hostname }}</div>
    
    <div class="progress-container">
        <div class="progress-bar"></div>
        <div class="nyan-cat">🐱</div>
        <div class="sparkles">
            <div class="sparkle">✨</div>
            <div class="sparkle">⭐</div>
            <div class="sparkle">✨</div>
            <div class="sparkle">⭐</div>
            <div class="sparkle">✨</div>
        </div>
    </div>
</body>
</html>
'''

@app.route("/")
def home():
    """Main route showing hostname with rainbow cat progress animation"""
    hostname = socket.gethostname()
    return render_template_string(HTML_TEMPLATE, hostname=hostname)

@app.route("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)