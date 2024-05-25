import os
from PIL import Image
import numpy as np
import matplotlib.pyplot as plt
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

# Images from the MNIST dataset
input_folder = "trainingSample"
output_folder = "trainingSample_resized"

# In our VHDL project, images are 256x256, black/white and mirrored => we must preprocess images!!!
preprocess_images(input_folder, output_folder)
X, y = load_data(output_folder)

# 80% train, 20% test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train perceptron
perceptron = Perceptron()
perceptron.fit(X_train, y_train)

scaling_factor = 5000  #we must use integers for VHDL exportation
weights_scaled = perceptron.coef_ * scaling_factor
bias_scaled = perceptron.intercept_ * scaling_factor

# In order to better visualise the perceptron weights, let's plot them
matrix = weights_scaled.reshape((256, 256))

# Create the heatmap and save to an external file
plt.imshow(matrix, cmap='hot', interpolation='nearest')
plt.colorbar()
plt.title('Heatmap of Perceptron Weights')
plt.savefig('heatmap.png')

# In our VHDL project, we set words in perceptron's RAM as 16 bits
num_bits = 16

# We use 2's complement to represent signed integers
weights_twos_complement = [convert_to_twos_complement(int(weight), num_bits) for weight in weights_scaled[0]]
bias_twos_complement = convert_to_twos_complement(int(bias_scaled[0]), num_bits)

# We create .mif file to initialize perceptron's RAM in our VHDL project
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

# Let's check our model's accuracy
accuracy = perceptron.score(X_test, y_test)
print("Perceptron accuracy:", accuracy)