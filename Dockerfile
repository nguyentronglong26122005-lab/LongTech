FROM php:8.2-apache

# Cài đặt extension PDO MySQL và unzip
RUN apt-get update && apt-get install -y unzip \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && a2enmod rewrite

# Bật AllowOverride All cho /var/www/ (giữ nguyên dấu / ở cuối để tránh lỗi mod_rewrite 500)
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Cấu hình cổng 10000 mặc định cho Render
RUN sed -i 's/80/10000/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Copy toàn bộ vào máy chủ
WORKDIR /var/www/html
COPY . /var/www/html/

# Tự động giải nén file zip chuẩn Linux nếu có và xóa sạch RewriteBase /LongTech/ nếu còn sót
RUN if [ -f "LongTech_Linux.zip" ]; then \
        unzip -o LongTech_Linux.zip -d /var/www/html/ \
        && rm -f LongTech_Linux.zip LongTech_Deploy.zip; \
    elif [ -f "LongTech_Deploy.zip" ]; then \
        unzip -o LongTech_Deploy.zip -d /var/www/html/ \
        && rm -f LongTech_Deploy.zip; \
    fi \
    && if [ -f "/var/www/html/.htaccess" ]; then \
        sed -i '/RewriteBase/d' /var/www/html/.htaccess; \
        sed -i 's/\r$//' /var/www/html/.htaccess; \
    fi

# Phân quyền thư mục
RUN mkdir -p /var/www/html/assets/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 10000

# Khởi động Apache và đảm bảo lắng nghe đúng cổng của Render ($PORT hoặc 10000)
CMD sed -i "s/Listen [0-9]*/Listen ${PORT:-10000}/g" /etc/apache2/ports.conf \
    && sed -i "s/<VirtualHost \*:[0-9]*>/<VirtualHost *:${PORT:-10000}>/g" /etc/apache2/sites-available/000-default.conf \
    && apache2-foreground
