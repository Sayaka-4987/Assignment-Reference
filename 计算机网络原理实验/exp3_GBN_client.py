from datetime import date, datetime
from socket import *
from time import *

LOCALHOST = '127.0.0.1'
PORT = 7999
WINDOW_SIZ = 3          # 窗口大小
PACKAGE_COUNT = 10      # 发送包的总数
TIME_OUT_LIMIT = 5      # 单位为秒

client = socket(AF_INET, SOCK_DGRAM)    # 也不知道为啥 SOCK_STREAM 不行 ……
setdefaulttimeout(TIME_OUT_LIMIT)            

# 丢包在服务器端    
print('Client is ready, 16.7% probability of packet loss.')

expect_seq = 0
next_seq = 0

# 一些生成的数据
def message_new(num) -> str:
    return "bla" * num

# 重传 (上次正确ACK, 当前传输进度) 区间内的数据
def send_again():
    global next_seq
    i = expect_seq
    while i < next_seq:
        cur_message = str(i) + ":" + message_new(i)
        print("Sending again:", cur_message)
        client.sendto(cur_message.encode(), (LOCALHOST, PORT))
        sleep(1)
        i += 1

# 发送 (当前传输进度, 包数) 的数据
def send_message():
    global next_seq
    while ((next_seq < expect_seq + WINDOW_SIZ) and (next_seq < PACKAGE_COUNT)):
        cur_message = str(next_seq) + ":" + message_new(next_seq)
        print("Sending:", cur_message)
        client.sendto(cur_message.encode(), (LOCALHOST, PORT))
        sleep(1)
        next_seq += 1


print("Client is ready for sending message ... ")        


while expect_seq != PACKAGE_COUNT:
    send_message()
    try:
        reply, add = client.recvfrom(1024)
    except:
        send_again()
        continue

    # int 会把字符转成 ascii 码，所以再减去一个 0 的 ascii 码 
    receive_ACK = int(reply[4] - 48)

    # 接收到正确顺序的 ACK 时，期待序列号加一
    if(expect_seq == receive_ACK):
        print("\n################################ \nFinally ACK: ", receive_ACK, "\nCorrect receiving sequence! \n")
        expect_seq = receive_ACK + 1
    
    # 数据顺序错误，重传错误区间段的数据
    else:
        print(reply.decode())
        send_again()    

# 发信让服务器停止接收
client.sendto("END".encode(), (LOCALHOST, PORT))
print("All the packet transferred successfully, bye!")