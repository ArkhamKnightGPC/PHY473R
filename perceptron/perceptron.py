import os
from PIL import Image
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import Perceptron

def resize_and_convert_to_bw(image_path, size=(256, 256)):
    # Open the image
    img = Image.open(image_path)
    # Resize the image
    img = img.resize(size)
    # Convert to grayscale
    img = img.convert('L')
    # Binarize the image
    threshold = 127
    img = img.point(lambda p: p > threshold and 255)
    return img

def preprocess_images(input_folder, output_folder):
    # Create output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    for class_folder in os.listdir(input_folder):
        if class_folder.isdigit():
            class_path = os.path.join(input_folder, class_folder)
            output_class_path = os.path.join(output_folder, class_folder)
            if not os.path.exists(output_class_path):
                os.makedirs(output_class_path)
            for img_file in os.listdir(class_path):
                if img_file.endswith(".jpg"):
                    img_path = os.path.join(class_path, img_file)
                    processed_img = resize_and_convert_to_bw(img_path)
                    output_img_path = os.path.join(output_class_path, img_file)
                    processed_img.save(output_img_path)

def load_data(input_folder):
    X = []
    y = []
    for class_folder in os.listdir(input_folder):
        if class_folder.isdigit():
            class_path = os.path.join(input_folder, class_folder)
            for img_file in os.listdir(class_path):
                if img_file.endswith(".jpg"):
                    img_path = os.path.join(class_path, img_file)
                    img = Image.open(img_path)
                    img_array = np.array(img).flatten() / 255.0
                    X.append(img_array)
                    y.append(int(class_folder))
    return np.array(X), np.array(y)

def convert_to_twos_complement(value, num_bits):
    if value < 0:
        value += (1 << num_bits)
    return value

# Define paths
input_folder = "trainingSample"
output_folder = "trainingSample_resized"

# Preprocess images
preprocess_images(input_folder, output_folder)

# Load data
X, y = load_data(output_folder)

# Split data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train perceptron
perceptron = Perceptron()
perceptron.fit(X_train, y_train)

# Scale weights and bias to integers
scaling_factor = 10000  # Adjust this value as needed to preserve precision
weights_scaled = perceptron.coef_ * scaling_factor
bias_scaled = perceptron.intercept_ * scaling_factor

# Determine the number of bits needed to represent the weights and bias
num_bits = 16  # Change this value based on your requirements

# Convert weights and bias to 2's complement representation
weights_twos_complement = [convert_to_twos_complement(int(weight), num_bits) for weight in weights_scaled[0]]
bias_twos_complement = convert_to_twos_complement(int(bias_scaled[0]), num_bits)

# Write to .mif file
with open('0_1.mif', 'w') as f:
    f.write("DEPTH = 65536;\n")
    f.write("WIDTH = {};\n".format(num_bits))
    f.write("ADDRESS_RADIX = DEC;\n")
    f.write("DATA_RADIX = BIN;\n")
    f.write("CONTENT\n")
    f.write("BEGIN\n")
    #f.write("0 : " + format(bias_twos_complement, '0{}b'.format(num_bits)) + ";\n")  # Write bias
    for i, weight in enumerate(weights_twos_complement):
        f.write("{} : ".format(i) + format(weight, '0{}b'.format(num_bits)) + ";\n")  # Write weights
    f.write("END;\n")

# Evaluate perceptron
accuracy = perceptron.score(X_test, y_test)
print("Perceptron accuracy:", accuracy)