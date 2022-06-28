from flask import Flask
import streamlink
import json

app = Flask(__name__)

@app.route("/")
def index():
    return "galaxy api"


@app.route("/<string:channel>")
def get_channel(channel):
    streams = streamlink.streams(f"https://twitch.tv/{channel}")

    video_urls = {}
    for entry in streams:
        video_urls[entry] = streams[entry].url

    return json.dumps(video_urls)
