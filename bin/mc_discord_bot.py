#!/usr/bin/env python3

from discord.ext import commands
import discord
import subprocess


# intentの設定
intents = discord.Intents.default()
intents.message_content = True  # メッセージの内容を読み取るために必要です

# Botの初期化時にintentsを指定
bot = commands.Bot(command_prefix='!', intents=intents)


@bot.event
async def on_ready():
    print(f'{bot.user} has connected to Discord!')


# コマンドの定義
# !startmc コマンドでサーバーを起動するシェルスクリプトを起動
@bot.command(name='startmc')
@commands.has_role('Server Admin')
async def start_mc(ctx):
    try:
        subprocess.run(
            ['bash', '/home/tekkamelon/github/tmux_mc.sh'],
            check=True
        )
        await ctx.send('マインクラフトサーバーを起動しました！')
    except subprocess.CalledProcessError as e:
        await ctx.send(f'エラーが発生しました: {str(e)}')

bot.run(
    'YOUR_DISCORD_BOT_TOKEN'
)
