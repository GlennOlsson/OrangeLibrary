# Use an official Swift runtime as a parent image
FROM swift:5.9.2

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

RUN mv .env Sources/mail-collect/Resources/secrets.txt

# Compile the Swift code
# RUN swift build

# Expose the port the app runs on

# Run the application
# CMD ["./.build/debug/YourSwiftApp"]
