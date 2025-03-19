# 2FA SMS Workflow for Alfred

[alfred-simple-2fa-paste](https://github.com/thebitguru/alfred-simple-2fa-paste)只支持提取Google的短信验证码，基于此优化
- 支持中文、英文短信验证码提取
- 支持按短信前缀指定验证码提取正则
- 图标更新为Mac Sequoia版本短信图标

## ⚙️ 使用

默认配置提取正则为`([[:alnum:]]{4,})`4位以上英文+数字，当遇到英文短信时自行前缀与正则，k=短信前缀，v=提取正则

> 如Google短信："【Google】G-602392 is your Google verification code. Don't share your code with anyone."。前缀=【Google】，提取正则为`G-([0-9]{6})`

![Preview](https://raw.githubusercontent.com/zhioak/pics/master/picgo/2025-03%2FiShot_2025-03-14_17.44.21-f98c44.png)

接收到短息输入2fa，选择对应的短信回车即可粘贴到对应焦点位

![Preview](https://raw.githubusercontent.com/zhioak/pics/master/picgo/2025-03%2FiShot_2025-03-14_17.32.16-109bf4.png)


## 特别鸣谢

- [alfred-simple-2fa-paste](https://github.com/thebitguru/alfred-simple-2fa-paste)