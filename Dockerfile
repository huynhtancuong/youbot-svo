FROM ros:noetic

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND noninteractive

# Timezone Configuration
ENV TZ=Europe/Moscow
ENV ROS_DISTRO=noetic
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get upgrade -y &&\
    apt-get install --no-install-recommends -y \
    git curl wget unzip tmux\
    net-tools vim lsb-release \ 
	build-essential gcc g++ cmake make \
	libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
	libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
    yasm libatlas-base-dev gfortran libpq-dev \
    libxine2-dev libglew-dev libtiff5-dev  zlib1g-dev libavutil-dev libpostproc-dev \ 
    python3-dev python3-pip libx11-dev tzdata apt-utils mesa-utils gnupg2 \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN apt-get update &&\ 
    apt-get install -y python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        python3-catkin-tools \
        python-lxml \
        build-essential \
    && rosdep update \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN mkdir -p /ros_ws/src && cd /ros_ws \ 
    && catkin config --extend /opt/ros/${ROS_DISTRO} \
    && catkin build && echo "source /ros_ws/devel/setup.bash" >> ~/.bashrc

# OpenCV and other libraries Installation
RUN apt-get update \
    && apt install -y libpcl-dev libeigen3-dev libboost-all-dev\
    && apt-get install -q -y openssh-client \
    && apt-get install -q -y ros-${ROS_DISTRO}-cv-bridge \
    && apt-get install -q -y python3-opencv \
    && apt-get update -y || true && apt-get install -y \ 
	&& apt-get install -y --no-install-recommends libopencv-dev \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN apt-get update &&\
    apt install -y ros-$ROS_DISTRO-realsense2-camera \
    ros-$ROS_DISTRO-realsense2-description \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

# Install ROS packages
RUN apt-get update \
    && apt-get install -y ros-${ROS_DISTRO}-rqt-joint-trajectory-controller \ 
        ros-${ROS_DISTRO}-ros-control \ 
        ros-${ROS_DISTRO}-velocity-controllers \
        ros-${ROS_DISTRO}-effort-controllers \ 
        ros-${ROS_DISTRO}-position-controllers \ 
        ros-${ROS_DISTRO}-robot-state-publisher \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN apt-get update \
    && apt-get install -y ros-${ROS_DISTRO}-roslint ros-${ROS_DISTRO}-pr2-msgs \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN apt-get update \
    && apt-get install -y ros-${ROS_DISTRO}-rviz \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

WORKDIR /ros_ws

RUN apt update && apt-get install -y python3-catkin-tools python3-vcstool python3-osrf-pycommon \
    && apt-get install -y libglew-dev libopencv-dev libyaml-cpp-dev \
    && apt-get install -y libblas-dev liblapack-dev libsuitesparse-dev ros-${ROS_DISTRO}-eigen-conversions \
        ros-${ROS_DISTRO}-tf-conversions ros-noetic-pcl-ros \
    && rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean

RUN cd /ros_ws \
    && catkin config --init --mkdirs --extend /opt/ros/${ROS_DISTRO} --cmake-args -DCMAKE_BUILD_TYPE=Release -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 \
    && catkin build && echo "source /ros_ws/devel/setup.bash" >> ~/.bashrc
# COPY ./rpg_svo_pro_open/dependencies.yaml /ros_ws/src/svo_pkg/rpg_svo_pro_open/dependencies.yaml
# RUN cd /ros_ws/src/svo_pkg \
#     && vcs-import < ./rpg_svo_pro_open/dependencies.yaml \
#     && touch minkindr/minkindr_python/CATKIN_IGNORE \
#     && sed -i 's/git@github.com:/https\:\/\/github.com\//g' /ros_ws/src/svo_pkg/dbow2_catkin/CMakeLists.txt
# COPY ./rpg_svo_pro_open/svo_online_loopclosing/vocabularies /ros_ws/src/svo_pkg/rpg_svo_pro_open/svo_online_loopclosing/vocabularies
# RUN cd /ros_ws/src/svo_pkg/rpg_svo_pro_open/svo_online_loopclosing/vocabularies && ./download_voc.sh

COPY ./robocup_pkg /ros_ws/src/robocup_pkg
COPY ./rpg_svo_pro_open /ros_ws/src/svo_pkg/rpg_svo_pro_open

RUN cd /ros_ws/src/svo_pkg \
    && vcs-import < ./rpg_svo_pro_open/dependencies.yaml \
    && touch minkindr/minkindr_python/CATKIN_IGNORE \
    && sed -i 's/git@github.com:/https\:\/\/github.com\//g' /ros_ws/src/svo_pkg/dbow2_catkin/CMakeLists.txt
RUN cd /ros_ws/src/svo_pkg/rpg_svo_pro_open/svo_online_loopclosing/vocabularies && ./download_voc.sh

RUN cd /ros_ws && catkin build