import random
from socket import *
from time import sleep

LOCALHOST = '127.0.0.1'
PORT = 7999
received_message = []
end_receive = 0

server = socket(AF_INET, SOCK_DGRAM)
server.bind((LOCALHOST, PORT))
print('Server is ready ... ')

while True:
    sentence, client_address = server.recvfrom(1024)
    sentence = sentence.decode()

    # 发送完成，结束传输
    if(sentence == "END"): 
        break

    # int 会把字符转成 ascii 码，所以再减去一个 0 的 ascii 码    
    print("Get message: " + sentence)
    seq = int(sentence[0]) - int('0')

    # 服务端接收成功，发对应的 ACK
    if random.randint(0, 6) != 0:
        print(seq)
        if seq == end_receive + 1:
            server.sendto(("ACK:%d"%(seq)).encode(), client_address)
            end_receive = seq
            received_message.append(sentence[1:])
            print("Last receive: ", end_receive)
        else:
            server.sendto(("ACK:%d"%(seq)).encode(), client_address)

    # 模拟丢包，睡眠 10 秒使连接超时
    else:
        print("\n !!! Attention: Packet ", seq ," loss! \n")
        sleep(10)

print("Finish! All the message is ", received_message)  
