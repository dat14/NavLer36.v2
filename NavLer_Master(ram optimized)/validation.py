from unoptimized.network import *
from unoptimized.data_process import *
import tensorflow as tf


def mainval():
    # Measuring program snipet execution time.
    start_time = time.time()

    # Get data.
    datasource = get_data()
    results = np.zeros((len(datasource.images), 2))

    images = tf.placeholder(tf.float32, [batch_size, 240, 320, 3])
    poses_x = tf.placeholder(tf.float32, [batch_size, 3])
    poses_q = tf.placeholder(tf.float32, [batch_size, 3])

    train_datasource, validation_datasource, test_datasource = train_validate_test_split(datasource)

    net = GoogLeNet({'data': images})

    # Assign output layers to variables.
    p1_x = net.layers['cls1_fc_pose_xyz']
    p1_q = net.layers['cls1_fc_pose_wpqr']
    p2_x = net.layers['cls2_fc_pose_xyz']
    p2_q = net.layers['cls2_fc_pose_wpqr']
    p3_x = net.layers['cls3_fc_pose_xyz']
    p3_q = net.layers['cls3_fc_pose_wpqr']

    # Normalize error from all of the branches for both position and orientation data.
    l1_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p1_x, poses_x)))) * 0.3
    l1_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p1_q, poses_q)))) * 150
    l2_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p2_x, poses_x)))) * 0.3
    l2_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p2_q, poses_q)))) * 150
    l3_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p3_x, poses_x)))) * 0.3
    l3_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p3_q, poses_q)))) * 150


    # Set GPU options
    gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.85)

    init = tf.global_variables_initializer()
    saver = tf.train.Saver()

    with tf.Session(config=tf.ConfigProto(gpu_options=gpu_options)) as sess:

        # Load the data
        sess.run(init)
        saver.restore(sess, path + 'PoseNet.ckpt')
        data_gen = gen_data_batch_val(validation_datasource)

        for i in range(len(validation_datasource.validation_images)):
            for j in range(10):

                np_images, pose_val = next(data_gen)
                feed = {images: np_images}

                predicted_x, predicted_q = sess.run([p3_x, p3_q], feed_dict=feed)

                pose_q = np.asarray(datasource.poses[i][3:6])
                pose_x = np.asarray(datasource.poses[i][0:3])
                predicted_x, predicted_q = sess.run([p3_x, p3_q], feed_dict=feed)

                pose_q = np.squeeze(pose_q)
                pose_x = np.squeeze(pose_x)
                predicted_q = np.squeeze(predicted_q)
                predicted_x = np.squeeze(predicted_x)

                # Compute Individual Sample Error
                q1 = pose_q / np.linalg.norm(pose_q)
                q2 = predicted_q / np.linalg.norm(predicted_q)
                d = abs(np.sum(np.multiply(q1, q2)))
                theta = 2 * np.arccos(d) * 180 / math.pi
                error_x = np.linalg.norm(pose_x - predicted_x)
                results[i, :] = [error_x, theta]
                print('Iteration:  ', i, '  Error XYZ (m):  ', error_x, '  Error Q (degrees):  ', theta)

            median_result = np.median(results, axis=0)
            print('Median error ', median_result[0], 'm  and ', median_result[1], 'degrees.')

if __name__ == '__mainval__':
    mainval()