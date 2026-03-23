#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Telegram 群组加入脚本
使用 Telethon 库尝试加入指定 Telegram 群组

前置要求:
1. 安装依赖: pip install telethon
2. 在 https://my.telegram.org/apps 申请 API ID 和 API Hash
3. 准备好手机号（国际格式，如 +86138xxxxxxxx）

使用方法:
    python join_telegram_group.py

首次运行会要求输入验证码，之后会自动保存 session 文件
"""

import asyncio
import os
import sys
from telethon import TelegramClient
from telethon.errors import (
    SessionPasswordNeededError,
    FloodWaitError,
    InviteHashExpiredError,
    InviteHashInvalidError,
    ChannelsTooMuchError,
    ChannelInvalidError,
    UserBannedInChannelError,
    RPCError
)
from telethon.tl.functions.channels import JoinChannelRequest
from telethon.tl.functions.messages import ImportChatInviteRequest

# ==================== 配置区域 ====================
# 请在此处填写你的 Telegram API 凭证
# 获取方式: https://my.telegram.org/apps

API_ID = 0           # 替换为你的 api_id (数字)
API_HASH = ""        # 替换为你的 api_hash (字符串)
PHONE_NUMBER = ""    # 替换为你的手机号，国际格式如 "+86138xxxxxxxx"

# 目标群组配置
TARGET_GROUP = "@fuli"  # 可以是 @username 或 invite link 或群组 ID
# TARGET_GROUP = "https://t.me/fuli"
# TARGET_GROUP = -1001234567890  # 群组 ID

# Session 文件名（会自动创建）
SESSION_NAME = "telegram_session"

# =================================================


def check_config():
    """检查配置是否有效"""
    if API_ID == 0 or not API_HASH or not PHONE_NUMBER:
        print("❌ 错误: 请先配置 API_ID, API_HASH 和 PHONE_NUMBER")
        print("\n📋 配置步骤:")
        print("1. 访问 https://my.telegram.org/apps 申请 API 凭证")
        print("2. 在脚本中填写 API_ID, API_HASH 和 PHONE_NUMBER")
        print("\n📝 示例配置:")
        print('   API_ID = 12345678')
        print('   API_HASH = "a1b2c3d4e5f6..."')
        print('   PHONE_NUMBER = "+86138xxxxxxxx"')
        return False
    return True


async def get_code():
    """从用户输入获取验证码"""
    return input("\n📱 请输入 Telegram 发送到你手机的验证码: ").strip()


async def get_password():
    """从用户输入获取两步验证密码"""
    return input("\n🔐 你的账号开启了两步验证，请输入密码: ").strip()


async def join_group(client, group_identifier):
    """
    尝试加入指定的 Telegram 群组
    
    参数:
        client: TelegramClient 实例
        group_identifier: 群组标识，可以是 @username, invite link, 或群组 ID
    """
    try:
        print(f"\n🔍 正在尝试加入群组: {group_identifier}")
        
        # 处理不同类型的群组标识
        if isinstance(group_identifier, str):
            group_identifier = group_identifier.strip()
            
            # 处理 invite link (https://t.me/+xxxxx 或 https://t.me/joinchat/xxxxx)
            if "/" in group_identifier and "t.me" in group_identifier:
                if "+" in group_identifier:
                    # 新格式: https://t.me/+xxxxx
                    hash_part = group_identifier.split("+")[-1].split("/")[0]
                    print(f"   检测到 invite link，hash: +{hash_part}")
                    result = await client(ImportChatInviteRequest(hash_part))
                elif "joinchat" in group_identifier:
                    # 旧格式: https://t.me/joinchat/xxxxx
                    hash_part = group_identifier.split("/")[-1].split("?")[0]
                    print(f"   检测到 joinchat link，hash: {hash_part}")
                    result = await client(ImportChatInviteRequest(hash_part))
                else:
                    # 公开群组链接: https://t.me/groupname
                    username = group_identifier.split("/")[-1].split("?")[0]
                    print(f"   检测到公开群组: @{username}")
                    entity = await client.get_entity(username)
                    result = await client(JoinChannelRequest(entity))
            elif group_identifier.startswith("@"):
                # @username 格式
                print(f"   使用 username: {group_identifier}")
                entity = await client.get_entity(group_identifier)
                result = await client(JoinChannelRequest(entity))
            elif group_identifier.lstrip("-").isdigit():
                # 群组 ID
                print(f"   使用群组 ID: {group_identifier}")
                entity = await client.get_entity(int(group_identifier))
                result = await client(JoinChannelRequest(entity))
            else:
                # 尝试作为 username 处理
                print(f"   尝试解析为: @{group_identifier}")
                entity = await client.get_entity(f"@{group_identifier}")
                result = await client(JoinChannelRequest(entity))
        else:
            # 直接使用实体 ID
            entity = await client.get_entity(group_identifier)
            result = await client(JoinChannelRequest(entity))
        
        print("\n✅ 成功加入群组!")
        
        # 尝试获取群组信息
        try:
            if hasattr(result, 'chats') and result.chats:
                chat = result.chats[0]
                print(f"\n📊 群组信息:")
                print(f"   名称: {getattr(chat, 'title', 'N/A')}")
                print(f"   ID: {chat.id}")
                if hasattr(chat, 'username') and chat.username:
                    print(f"   Username: @{chat.username}")
                if hasattr(chat, 'participants_count'):
                    print(f"   成员数: {chat.participants_count}")
        except Exception as e:
            pass  # 忽略获取额外信息的错误
            
        return True
        
    except FloodWaitError as e:
        print(f"\n❌ 失败: 操作过于频繁")
        print(f"   需要等待 {e.seconds} 秒后才能再次尝试")
        print(f"   建议: 请稍后再试，或更换账号")
        return False
        
    except InviteHashExpiredError:
        print(f"\n❌ 失败: 邀请链接已过期")
        print(f"   建议: 请获取新的邀请链接")
        return False
        
    except InviteHashInvalidError:
        print(f"\n❌ 失败: 邀请链接无效")
        print(f"   建议: 请检查链接是否正确")
        return False
        
    except ChannelsTooMuchError:
        print(f"\n❌ 失败: 加入的频道/群组数量已达上限")
        print(f"   建议: 请先退出一些不用的群组")
        return False
        
    except ChannelInvalidError:
        print(f"\n❌ 失败: 群组无效或不存在")
        print(f"   建议: 请检查群组标识是否正确")
        return False
        
    except UserBannedInChannelError:
        print(f"\n❌ 失败: 你已被该群组封禁")
        print(f"   建议: 无法加入此群组，请尝试其他群组")
        return False
        
    except RPCError as e:
        print(f"\n❌ 失败: Telegram API 错误")
        print(f"   错误信息: {e}")
        return False
        
    except Exception as e:
        print(f"\n❌ 失败: 未知错误")
        print(f"   错误类型: {type(e).__name__}")
        print(f"   错误信息: {e}")
        return False


async def main():
    """主函数"""
    print("=" * 50)
    print("  Telegram 群组加入工具")
    print("=" * 50)
    
    # 检查配置
    if not check_config():
        sys.exit(1)
    
    # 检查是否安装了 telethon
    try:
        import telethon
    except ImportError:
        print("\n❌ 错误: 未安装 Telethon 库")
        print("\n📦 安装命令:")
        print("   pip install telethon")
        sys.exit(1)
    
    # 创建客户端
    client = TelegramClient(SESSION_NAME, API_ID, API_HASH)
    
    try:
        print(f"\n📡 正在连接到 Telegram...")
        
        # 启动客户端
        await client.start(
            phone=PHONE_NUMBER,
            code_callback=get_code,
            password=get_password if client.is_user_authorized else None
        )
        
        print("✅ 登录成功!")
        
        # 获取当前用户信息
        me = await client.get_me()
        print(f"\n👤 当前账号:")
        print(f"   名称: {me.first_name} {me.last_name or ''}")
        print(f"   Username: @{me.username or '未设置'}")
        print(f"   手机号: +{me.phone}")
        
        # 尝试加入群组
        success = await join_group(client, TARGET_GROUP)
        
        print("\n" + "=" * 50)
        if success:
            print("  结果: 成功加入群组")
        else:
            print("  结果: 加入失败")
        print("=" * 50)
        
    except SessionPasswordNeededError:
        print("\n❌ 错误: 需要两步验证密码但未提供")
        print("   建议: 请重新运行脚本并输入密码")
        
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        
    finally:
        await client.disconnect()
        print("\n🔌 已断开连接")


if __name__ == "__main__":
    # Windows 需要设置事件循环策略
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⚠️ 用户中断操作")
        sys.exit(0)
