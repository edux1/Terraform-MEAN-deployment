provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.region
}

resource "aws_security_group" "security_group" {
    name        = "security-group"
    description = "Permite el trafico HTTP, SSH y al puerto 20717"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 27017
        to_port   = 27017
        protocol  = "tcp"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "nodejs" {
    # Creando dos instancias con NodeJS
    count = 2
    tags = {
        Name = "Nodejs${count.index + 1}"
    }

    ami                     = "ami-0779b9e9deabf606b"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.security_group.id]
    key_name                = "lab"

    # Añadiendo fichero JS en /var/www/app para usar como app
    provisioner "file" {
        content = <<-EOT
            const express = require('express')
            const app = express()
            const port = 3000

            app.get('/', (req, res) => {
            res.send("Hola Mundo! Soy Eduardo Pinto, estudiante de UNIR!\nServer IP: ${self.public_ip}\nConnection string: mongodb://${aws_instance.mongodb.public_ip}:27017")
            })

            app.listen(port, () => {
            console.log("Example app listening on port " + port)
            })
        EOT 

        destination = "/var/www/app/hello.js"

        connection {
            type        = "ssh"
            user        = "ubuntu"
            private_key = file("lab.pem")
            host        = self.public_ip
        }
    }

    # Reiniciando app para usar el nuevo fichero actualizado
    provisioner "remote-exec" {
        inline = [
            "cd /var/www/app/",
            "pm2 stop hello.js",
            "pm2 start hello.js --name hello"
        ]

        connection {
            type        = "ssh"
            user        = "ubuntu"
            private_key = file("lab.pem")
            host        = self.public_ip
        }
    }
}

resource "aws_instance" "mongodb" {
    tags = {
        Name = "mongodb"
    }
    ami                     ="ami-0a2359bea53bf74e8"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.security_group.id]
}

output "connection_string" {
    value = "mongodb://${aws_instance.mongodb.public_ip}:27017"
}