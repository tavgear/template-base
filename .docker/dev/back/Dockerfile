FROM node:24-slim

ENV NODE_ENV=development

ARG UID
ARG UNAME

# Install base utilities
RUN apt-get update && apt-get install -y curl ca-certificates && rm -rf /var/lib/apt/lists/*

# Create development user to match host UID
RUN getent passwd ${UID} > /dev/null 2>&1 || useradd -u ${UID} -g www-data -M ${UNAME}

WORKDIR /app

USER ${UID}

# Start Strapi in development
CMD ["npm", "run", "develop"]
