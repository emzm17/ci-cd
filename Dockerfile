# Use official Node.js LTS base image
FROM node:18-alpine

# Set working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Expose the app's port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
