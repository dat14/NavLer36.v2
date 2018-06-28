
from ram_optimized.network import *
from ram_optimized.parallel_data_process import *
import tensorflow as tf
from tensorflow.python.client import timeline


def main():
    # Measuring program snipet execution time.
    start_time = time.time()

    images = tf.placeholder(tf.float32, [batch_size, 240, 320, 3])
    poses_x = tf.placeholder(tf.float32, [batch_size, 3])
    poses_q = tf.placeholder(tf.float32, [batch_size, 3])

    # Get data.
    datasource = get_data()

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
    l1_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p1_x, poses_x))))   * 0.3
    l1_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p1_q, poses_q))))   * 150
    l2_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p2_x, poses_x))))   * 0.3
    l2_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p2_q, poses_q))))   * 150
    l3_x = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p3_x, poses_x))))   * 0.3
    l3_q = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(p3_q, poses_q))))   * 150

    # Normalized loss function
    loss = (l1_x + l1_q + l2_x + l2_q + l3_x + l3_q)/3

    #Adam optimizer with set parameters.
    opt = tf.train.AdamOptimizer(learning_rate=0.0001, beta1=0.9, beta2=0.999, epsilon=0.00000001,
                                 use_locking=False,
                                 name='Adam').minimize(loss)


    # Set number of iterations.
    max_iterations = 100

    # Set GPU options for VRAM allocation.
    gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.85)

    init = tf.global_variables_initializer()

    #Initialize graph, weight saver.
    saver = tf.train.Saver()
    outputFile = directory + "PoseNet.ckpt"

    with tf.Session(config=tf.ConfigProto(gpu_options=gpu_options)) as sess:

        sess.run(init)
        options = tf.RunOptions(trace_level=tf.RunOptions.FULL_TRACE)
        run_metadata = tf.RunMetadata()

        #Load pretrained weights.
        saver.restore(sess, path + 'PoseNet.ckpt')
        # net.load('/home/duyan/Downloads/PseudoCorridor/Pass1/input_data/posenet.npy', sess)

        data_gen = gen_data_batch(train_datasource)

        #Prints the time after the start at every 20th iteration and print the value of the loss function and saves the weights at every 100 iterations.
        for i in range(max_iterations):
            np_images, np_poses_x, np_poses_q = next(data_gen)
            feed = {images: np_images, poses_x: np_poses_x, poses_q: np_poses_q}

            sess.run(opt, feed_dict=feed)
            np_loss = sess.run(loss, feed_dict=feed,
                               options=options,
                               run_metadata=run_metadata)

            if i % 20 == 0:
                # print("iteration: " + str(i) + "\n\t" + "Loss is: " + str(np_loss))
                print("iteration: " + str(i) + ": --- " + str(time.time() - start_time) + " seconds ---")

            if i % 100 == 0:
                print("iteration: " + str(i) + ": Loss is: " + str(np_loss))
                saver.save(sess, outputFile)
                print("iteration: " + str(i) + ": --- Intermediate file saved at: " + outputFile)

            fetched_timeline = timeline.Timeline(run_metadata.step_stats)
            chrome_trace = fetched_timeline.generate_chrome_trace_format()

        with open("C:/Users/DuyAn/Desktop/New folder/Corridorka/timeline_02_step_d69.json", 'w') as f:
            f.write(chrome_trace)

        saver.save(sess, outputFile)
        print("iteration: " + str(i) + ": --- Intermediate file saved at: " + outputFile)

    print("\n%s seconds ---" % (time.time() - start_time))


if __name__ == '__main__':
    main()
