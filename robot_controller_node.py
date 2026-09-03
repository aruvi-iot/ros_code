import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


class RobotController(Node):

    def __init__(self):
        super().__init__('robot_controller')

        self.publisher = self.create_publisher(
            Twist,
            '/cmd_vel',
            10
        )

        self.timer = self.create_timer(1.0, self.move_robot)

    def move_robot(self):
        msg = Twist()

        msg.linear.x = 1.0
        msg.angular.z = 0.0

        self.publisher.publish(msg)

        self.get_logger().info('Robot moving forward')


def main(args=None):
    rclpy.init(args=args)

    node = RobotController()

    rclpy.spin(node)

    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
