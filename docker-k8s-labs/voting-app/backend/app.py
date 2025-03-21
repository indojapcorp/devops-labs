from flask import Flask, request
import redis
import boto3
import os

app = Flask(__name__)
r = redis.Redis(host='redis', port=6379, decode_responses=True)
s3 = boto3.client('s3', endpoint_url='http://localhost:4566', aws_access_key_id='test', aws_secret_access_key='test')

@app.route('/vote', methods=['POST'])
def vote():
    vote = request.json['vote']
    r.incr(vote)
    s3.put_object(Bucket='votes-bucket', Key=f'vote-{vote}', Body=vote.encode())
    return 'Vote recorded', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)