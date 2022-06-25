import smtplib

from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr

def _format_address(s):
    name, address = parseaddr(s)
    return formataddr((Header(name, 'utf-8').encode(), address))


# Email 地址和口令:
from_address = input('Email: ')
password = input('Password: ')

# 收件人地址:
to_address = input('To: ')

# 邮件内容
string = input('Enter the mail content: ')
msg = MIMEText(string, 'plain', 'utf-8')

# SMTP服务器地址:
smtp_server = "smtp.163.com"

# 发件人显示效果
msg['From'] = _format_address('WYX实验2的SMTP服务 <%s>' % from_address)

# 收件人显示效果
msg['To'] = _format_address('19281171 <%s>' % to_address)

# 标题
msg['Subject'] = Header('SMTP 邮件发送测试', 'utf-8').encode()

# SMTP 协议默认端口号25
server = smtplib.SMTP(smtp_server, 25)

# 显示发送信息
server.set_debuglevel(1)
server.login(from_address, password)
server.sendmail(from_address, [to_address], msg.as_string())
server.quit()
