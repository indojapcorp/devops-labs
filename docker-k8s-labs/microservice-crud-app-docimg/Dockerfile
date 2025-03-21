# Step 1: Use the official Node.js image as the base image
FROM node:18

# Step 2: Set working directory inside the container
WORKDIR /app

# Step 3: Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Step 4: Copy the rest of the app code into the container
COPY . .

# Step 5: Expose the application port
EXPOSE 3000

# Step 6: Start the app
CMD ["node", "app.js"]
