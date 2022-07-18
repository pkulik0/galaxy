import json
import streamlink
from flask import Flask


app = Flask(__name__)
session = streamlink.Streamlink()
session.set_plugin_option("twitch", "low-latency", True)


@app.route("/")
def index():
    return "galaxy api"


@app.route("/<string:channel>")
def get_channel(channel):
    streams = session.streams(f"https://twitch.tv/{channel}")

    video_urls = {}
    for entry in streams:
        video_urls[entry] = streams[entry].url

    return json.dumps(video_urls)
