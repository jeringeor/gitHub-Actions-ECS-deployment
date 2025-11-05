# Use the official lightweight Python image.
FROM python:3.11-slim

# Set the working directory inside the container.
WORKDIR /app

# Copy the Python dependencies file and install dependencies.
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code.
COPY . /app/

# Expose port 80 for Flask to run on.
EXPOSE 80

# Run the application.
CMD ["python", "app.py"]
