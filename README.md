Сборка nginx из исходников используя Debian9 и multistage-build

#Собираем образ из Dockerfile 
docker build -t nginx .

#запускаем контейнер с монтированием файла конфигурации 
docker run -ti --rm -d -p 127.0.0.1:8089:80 --name web -v $PWD/site.conf:/etc/nginx/sites-enabled/site.conf nginx

это единственный активный конфиг, слушающий 80 порт и отвечающий на все запросы кодом 200 и текстом "Nginx отвечает кодом 200"

#проверяем работоспособность
curl -i 127.0.0.1:8089

HTTP/1.1 200 OK
Server: nginx/1.18.0
Date: Thu, 20 Aug 2020 05:43:49 GMT
Content-Type: application/octet-stream
Content-Length: 38
Connection: keep-alive
Content-Type: text/plain

Nginx отвечает кодом 200


