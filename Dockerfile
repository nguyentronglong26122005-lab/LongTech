FROM php:8.2-apache

# Cài đặt extension PDO MySQL và unzip
RUN apt-get update && apt-get install -y unzip \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && a2enmod rewrite

# Cấu hình DocumentRoot
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Copy toàn bộ vào máy chủ
WORKDIR /var/www/html
COPY . /var/www/html/

# Tự động giải nén file zip chuẩn Linux
RUN if [ -f "LongTech_Linux.zip" ]; then \
        unzip -o LongTech_Linux.zip -d /var/www/html/ \
        && rm -f LongTech_Linux.zip LongTech_Deploy.zip; \
    elif [ -f "LongTech_Deploy.zip" ]; then \
        unzip -o LongTech_Deploy.zip -d /var/www/html/ \
        && rm -f LongTech_Deploy.zip; \
    fi

# Phân quyền thư mục
RUN mkdir -p /var/www/html/assets/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
