FROM postgres:16.3

# RUN echo 'Acquire::AllowInsecureRepositories "true";' > /etc/apt/apt.conf.d/99insecure && \
#     echo 'Acquire::AllowDowngradeToInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure

# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FAA4
# RUN apt update 
# RUN apt install -y --allow-unauthenticated  curl gnupg lsb-release

# # # Añadir claves GPG necesarias
# # RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/postgresql.gpg

# # Confirmar que tienes el repositorio pgdg habilitado correctamente
# RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
#     > /etc/apt/sources.list.d/pgdg.list

# RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

    # Ahora puedes instalar cron y partman
RUN apt update && \
    apt-get install -y  postgresql-16-cron postgresql-16-partman && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

