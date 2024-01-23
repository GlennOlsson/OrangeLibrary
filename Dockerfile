# Use an official Swift runtime as a parent image
FROM swift:latest

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Compile the Swift code
RUN swift build

# Expose the port the app runs on
EXPOSE 8080

# Run the application
CMD ["./.build/debug/YourSwiftApp"]
