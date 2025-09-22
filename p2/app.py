from flask import Flask, render_template_string
import socket
import os
import platform
import psutil
from datetime import datetime
import uuid

app = Flask(__name__)

# HTML Template with modern design
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask in Kubernetes - Status Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            position: relative;
            overflow-x: hidden;
        }

        /* Animated background elements */
        .bg-shapes {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: -1;
        }

        .shape {
            position: absolute;
            opacity: 0.1;
            animation: float 15s infinite linear;
        }

        .shape:nth-child(1) {
            top: 20%;
            left: 20%;
            width: 80px;
            height: 80px;
            background: white;
            border-radius: 50%;
            animation-delay: 0s;
        }

        .shape:nth-child(2) {
            top: 60%;
            left: 80%;
            width: 120px;
            height: 120px;
            background: white;
            clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
            animation-delay: 5s;
        }

        .shape:nth-child(3) {
            top: 40%;
            left: 10%;
            width: 60px;
            height: 60px;
            background: white;
            clip-path: polygon(25% 0%, 100% 0%, 75% 100%, 0% 100%);
            animation-delay: 10s;
        }

        @keyframes float {
            0% {
                transform: translateY(0px) rotate(0deg);
            }
            50% {
                transform: translateY(-20px) rotate(180deg);
            }
            100% {
                transform: translateY(0px) rotate(360deg);
            }
        }

        .container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            max-width: 800px;
            width: 100%;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .header {
            margin-bottom: 40px;
        }

        .main-title {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 10px;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .subtitle {
            font-size: 1.2rem;
            color: #666;
            margin-bottom: 30px;
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }

        .status-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            border-left: 4px solid #667eea;
        }

        .status-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
        }

        .card-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: #333;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .card-value {
            font-size: 1.4rem;
            font-weight: 700;
            color: #667eea;
            word-break: break-all;
        }

        .emoji {
            font-size: 1.5rem;
        }

        .timestamp {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #888;
            font-size: 0.9rem;
        }

        .kubernetes-badge {
            display: inline-block;
            background: linear-gradient(135deg, #326ce5, #1e3a8a);
            color: white;
            padding: 8px 16px;
            border-radius: 25px;
            font-size: 0.9rem;
            font-weight: 600;
            margin-top: 20px;
            box-shadow: 0 4px 15px rgba(50, 108, 229, 0.3);
        }

        .health-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            background: #4ade80;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% {
                box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7);
            }
            70% {
                box-shadow: 0 0 0 10px rgba(74, 222, 128, 0);
            }
            100% {
                box-shadow: 0 0 0 0 rgba(74, 222, 128, 0);
            }
        }

        @media (max-width: 768px) {
            .main-title {
                font-size: 2rem;
            }
            .container {
                padding: 25px;
            }
            .status-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="bg-shapes">
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
    </div>
    
    <div class="container">
        <div class="header">
            <h1 class="main-title">
                <span class="health-indicator"></span>
                Hello from {{ hostname }}!
            </h1>
            <p class="subtitle">Flask Application running in Kubernetes</p>
            <div class="kubernetes-badge">⎈ Kubernetes Ready</div>
        </div>
        
        <div class="status-grid">
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🖥️</span>
                    Hostname
                </div>
                <div class="card-value">{{ hostname }}</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🌐</span>
                    IP Address
                </div>
                <div class="card-value">{{ ip_address }}</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">💻</span>
                    Platform
                </div>
                <div class="card-value">{{ platform_info }}</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🐍</span>
                    Python Version
                </div>
                <div class="card-value">{{ python_version }}</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🧠</span>
                    Memory Usage
                </div>
                <div class="card-value">{{ memory_usage }}%</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">⚡</span>
                    CPU Usage
                </div>
                <div class="card-value">{{ cpu_usage }}%</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🆔</span>
                    Instance ID
                </div>
                <div class="card-value">{{ instance_id }}</div>
            </div>
            
            <div class="status-card">
                <div class="card-title">
                    <span class="emoji">🏃</span>
                    Uptime
                </div>
                <div class="card-value">{{ uptime }}</div>
            </div>
        </div>
        
        <div class="timestamp">
            Last updated: {{ timestamp }}
        </div>
    </div>
</body>
</html>
'''

# Store start time for uptime calculation
start_time = datetime.now()

def get_system_info():
    """Gather system information"""
    try:
        # Get hostname
        hostname = socket.gethostname()
        
        # Get IP address
        try:
            # Try to get the actual IP by connecting to a remote address
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip_address = s.getsockname()[0]
            s.close()
        except:
            ip_address = socket.gethostbyname(hostname)
        
        # Platform info
        platform_info = f"{platform.system()} {platform.release()}"
        
        # Python version
        python_version = platform.python_version()
        
        # Memory usage
        memory = psutil.virtual_memory()
        memory_usage = round(memory.percent, 1)
        
        # CPU usage
        cpu_usage = round(psutil.cpu_percent(interval=1), 1)
        
        # Generate instance ID (useful for container identification)
        instance_id = str(uuid.uuid4())[:8]
        
        # Calculate uptime
        uptime_delta = datetime.now() - start_time
        hours, remainder = divmod(uptime_delta.total_seconds(), 3600)
        minutes, seconds = divmod(remainder, 60)
        uptime = f"{int(hours):02d}:{int(minutes):02d}:{int(seconds):02d}"
        
        # Current timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        
        return {
            'hostname': hostname,
            'ip_address': ip_address,
            'platform_info': platform_info,
            'python_version': python_version,
            'memory_usage': memory_usage,
            'cpu_usage': cpu_usage,
            'instance_id': instance_id,
            'uptime': uptime,
            'timestamp': timestamp
        }
    except Exception as e:
        # Fallback info if some system calls fail
        return {
            'hostname': socket.gethostname(),
            'ip_address': 'Unknown',
            'platform_info': 'Unknown',
            'python_version': platform.python_version(),
            'memory_usage': 'N/A',
            'cpu_usage': 'N/A',
            'instance_id': 'Unknown',
            'uptime': 'N/A',
            'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        }

@app.route("/")
def home():
    """Main route with enhanced system information"""
    system_info = get_system_info()
    return render_template_string(HTML_TEMPLATE, **system_info)

@app.route("/health")
def health_check():
    """Health check endpoint for Kubernetes"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "hostname": socket.gethostname()
    }

@app.route("/api/info")
def api_info():
    """JSON API endpoint with system information"""
    return get_system_info()

if __name__ == "__main__":
    print(f"🚀 Starting Flask app on {socket.gethostname()}")
    print(f"📍 Access the app at http://localhost:5000")
    print(f"🏥 Health check available at http://localhost:5000/health")
    print(f"📊 API info available at http://localhost:5000/api/info")
    app.run(host="0.0.0.0", port=5000, debug=False)