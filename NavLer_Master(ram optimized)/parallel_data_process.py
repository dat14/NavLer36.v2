from ram_optimized.asset_import import *

# Define batch size.
batch_size = 32

# Set this path to your dataset directory
path = "C:/Users/DuyAn/Desktop/New folder/Corridorka/"
directory = "C:/Users/DuyAn/Desktop/New folder/Corridorka/"
dataset = "ground_truth.csv"

# Noise generator if the dataset is not enough diverse.
def noise_generator(noise_type, image):
    """
    Generate noise to a given Image based on required noise type

    Input parameters:
        image: ndarray (input image data. It will be converted to float)

        noise_type: string
            'gauss'        Gaussian-distrituion based noise
            'poission'     Poission-distribution based noise
            's&p'          Salt and Pepper noise, 0 or 1
            'speckle'      Multiplicative noise using out = image + n*image
                           where n is uniform noise with specified mean & variance
    """
    row, col, ch = image.shape
    if noise_type == "gauss":
        mean = 0.0
        var = 0.05
        sigma = var ** 0.5
        gauss = np.array(image.shape)
        gauss = np.random.normal(mean, sigma, (row, col, ch))
        gauss = gauss.reshape(row, col, ch)
        noisy = image + gauss
        return image
    elif noise_type == "s&p":
        s_vs_p = 0.5
        amount = 0.004
        out = image
        # Generate Salt '1' noise
        num_salt = np.ceil(amount * image.size * s_vs_p)
        coords = [np.random.randint(0, i - 1, int(num_salt))
                  for i in image.shape]
        out[coords] = 255
        # Generate Pepper '0' noise
        num_pepper = np.ceil(amount * image.size * (1. - s_vs_p))
        coords = [np.random.randint(0, i - 1, int(num_pepper))
                  for i in image.shape]
        out[coords] = 0
        return out
    elif noise_type == "poisson":
        val = len(np.unique(image))
        val = 2 ** np.ceil(np.log2(val))
        noisy = np.random.poisson(image * val) / float(val)
        return noisy
    elif noise_type == "speckle":
        gauss = np.random.randn(row, col, ch)
        gauss = gauss.reshape(row, col, ch)
        noisy = image + image * gauss
        return noisy
    else:
        return image

# Defining the train, test, validation datapackages.
class datasource(object):
    def __init__(self, images, poses):
        self.images = images
        self.poses = poses


class train_datasource(object):
    def __init__(self, train_images, train_poses):
        self.train_images = train_images
        self.train_poses = train_poses


class validation_datasource(object):
    def __init__(self, validation_images, validation_poses):
        self.validation_images = validation_images
        self.validation_poses = validation_poses


class test_datasource(object):
    def __init__(self, test_images, test_poses):
        self.test_images = test_images
        self.test_poses = test_poses


class datasource_split(object):
    def __init__(self, train_datasource, validation_datasource, test_datasource):
        self.train = train_datasource
        self.validation = validation_datasource
        self.test = test_datasource

# Additional function if the input images need real time cropping.
def preprocess_centerred_crop(img, output_side_length1, output_side_length2):
    height, width, depth = img.shape
    new_height = output_side_length1
    new_width = output_side_length2
    height_offset = (new_height - output_side_length1) / 2
    width_offset = (new_width - output_side_length2) / 2
    cropped_img = img[height_offset:height_offset + output_side_length1,
                  width_offset:width_offset + output_side_length2]
    return cropped_img

# Just to make sure the images are in usable numpy array format.
def preprocess_read_images_to_array(images):
    # semi results
    image_out = []
    for i in tqdm(range(len(images))):
        X = Image.open(images)
        X.load()
        X = np.asarray(X, dtype="int32")
        image_out.append(X)
    return image_out

# Subtract the mean of the given dataset from all images in order to improve efficiency.
def preprocess_subtract_mean(image_list):
    # Output
    images_out = []
    # Resize and crop and compute mean
    N = 0
    mean = np.zeros((1, 3, 240, 320))
    for X in tqdm(image_list):
        mean[0][0] += X[:, :, 0]
        mean[0][1] += X[:, :, 1]
        mean[0][2] += X[:, :, 2]
        N += 1
    mean[0] /= N
    # Subtract mean from all images

    for X in tqdm(image_list):
        X = np.transpose(X, (2, 0, 1))
        X = X - mean
        X = np.squeeze(X)
        X = np.transpose(X, (1, 2, 0))
        images_out.append(X)
    return images_out

# Convert ground_truth data from input csv files to numpy list.
def get_data():

    poses = []
    image_list = []
    with open("C:/Users/DuyAn/Desktop/New folder/Corridorka/ground_truth_C1_P1.csv") as f:
        for line in tqdm(f):
            flame, p0, p1, p2, p3, p4, p5 = line.split(",")
            p0 = float(p0)
            p1 = float(p1)
            p2 = float(p2)
            p3 = float(p3)
            p4 = float(p4)
            p5 = float(p5)
            poses.append([p0, p1, p2, p3, p4, p5
                          ])
            image_list.append(directory + flame)
    return datasource(image_list, poses)

# Shuffle then split the dataset with the user given ratio.
def train_validate_test_split(df, train_percent=.6, validate_percent=.2, seed=None):
    np.random.seed(seed)
    perm = list(range(len(df.images)))
    random.shuffle(perm)

    print(type(df.images))

    m = len(df.images)
    train_end = int(train_percent * m)
    validate_end = int(validate_percent * m) + train_end

    print("m: %d" % m)
    print(type(m))

    for i in perm:
        images = df.images[i]
        poses = df.poses[i]

    train_images = df.images[:train_end]
    print("train_images lenght: %d" % len(train_images))

    validation_images = df.images[train_end:validate_end]
    print("validation_images lenght: %d" % len(validation_images))

    test_images = df.images[validate_end:]
    print("test_images lenght: %d" % len(test_images))

    train_poses = df.poses[:train_end]
    print("train_poses lenght: %d" % len(train_poses))

    validation_poses = df.poses[train_end:validate_end]
    print("validation_poses lenght: %d" % len(validation_poses))

    test_poses = df.poses[validate_end:]
    print("test_poses lenght: %d" % len(test_poses))

    return train_datasource(train_images, train_poses), validation_datasource(validation_images,
                                                                              validation_poses), test_datasource(
        test_images, test_poses)

# Generate train data for feeding in the neural network.
def gen_data(source):
    while True:
        indices = list(range(len(source.train_images)))
        random.shuffle(indices)
        for i in indices:
            image = source.train_images[i]
            pose_x = source.train_poses[i][0:3]
            pose_q = source.train_poses[i][3:6]
            yield image, pose_x, pose_q

# Generate validatoin data for feeding in the neural network.
def gen_data_val(source):
    indices = list(range(len(source.validation_images)))
    for i in indices:
        image = source.validation_images[i]
        pose = source.validation_poses[i]
        yield image, pose

# Batch forming with optional noise generating.
def gen_data_batch(source):
    data_gen = gen_data(source)
    while True:
        image_batch = []
        pose_x_batch = []
        pose_q_batch = []
        for _ in range(batch_size):
            image, pose_x, pose_q = next(data_gen)
            X = Image.open(image)
            X.load()
            X = np.asarray(X, dtype="int32")
            #X = noise_generator("gauss", X)
            #X = noise_generator("s&p", X)
            #X = noise_generator("poisson", X)
            #X = noise_generator("speckle", X)
            image_batch.append(X)
            pose_x_batch.append(pose_x)
            pose_q_batch.append(pose_q)
        yield np.array(image_batch), np.array(pose_x_batch), np.array(pose_q_batch)

# Batch forming for validation data with optional noise generating.
def gen_data_batch_val(source):
    data_gen = gen_data_val(source)
    while True:
        image_batch = []
        pose_val_batch = []
        for _ in range(batch_size):
            image, pose_val = next(data_gen)
            image_batch.append(image)
            pose_val_batch.append(pose_val)
        yield np.array(image_batch), np.array(pose_val_batch)
