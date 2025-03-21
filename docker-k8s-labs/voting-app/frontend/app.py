from flask import Flask, request, render_template_string
import requests

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def vote():
    if request.method == 'POST':
        vote = request.form['vote']
        requests.post('http://backend:5001/vote', json={'vote': vote})
    return render_template_string('''
        <form method="POST">
            <button name="vote" value="yes">Yes</button>
            <button name="vote" value="no">No</button>
        </form>
    ''')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)