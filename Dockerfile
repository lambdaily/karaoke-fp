# Karaoke Forever Docker Image
# Con soporte completo para generación de karaoke desde YouTube
FROM node:22.14.0-bookworm

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    ffmpeg \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python

# Crear entorno virtual de Python
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Instalar librerías Python para procesamiento de karaoke
# - demucs: separación de vocales/instrumentales
# - whisperx: alineación de letras sincronizadas
# - faster-whisper: transcripción de audio optimizada
# - torch/torchaudio: backend de ML
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
    demucs==4.0.1 \
    whisperx==3.7.4 \
    faster-whisper==1.2.1 \
    torch==2.8.0 \
    torchaudio==2.8.0

# Verificar instalaciones
RUN node --version && \
    python3 --version && \
    ffmpeg -version | head -1 && \
    python -c "import demucs; print('Demucs OK')" && \
    python -c "import whisperx; print('WhisperX OK')"

# Crear directorio de la app
WORKDIR /app

# Copiar package files primero (mejor cache de Docker)
COPY package*.json ./

# Instalar dependencias de Node.js
RUN npm install

# Copiar el resto del código
COPY . .

# Build del frontend
RUN npm run build

# Crear directorios necesarios
RUN mkdir -p /app/data /app/tmp

# Puerto por defecto
EXPOSE 3000

# Volúmenes para datos persistentes
VOLUME ["/app/data", "/app/tmp"]

# Variables de entorno
ENV NODE_ENV=production
ENV KF_SERVER_PATH_DATA=/app/data
ENV PATH="/opt/venv/bin:$PATH"

# Comando de inicio
CMD ["node", "server/main.js", "-p", "3000"]
