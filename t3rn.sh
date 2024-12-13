#!/bin/bash

# Đường dẫn lưu script
DUONG_DAN_SCRIPT="$HOME/t3rn.sh"
FILE_NHAT_KY="$HOME/executor/executor.log"

# Kiểm tra xem script có được chạy bằng quyền root hay không
if [ "$(id -u)" != "0" ]; then
    echo "Script này cần được chạy bằng quyền root."
    echo "Hãy sử dụng lệnh 'sudo -i' để chuyển sang quyền root và chạy lại script."
    exit 1
fi

# Hàm menu chính
function menu_chinh() {
    while true; do
        clear
        echo "================================================================"
        echo "======================= Trình quản lý Node ======================="
        echo "================================================================"
        echo "Để thoát script, nhấn tổ hợp phím Ctrl + C."
        echo "Chọn một tác vụ muốn thực hiện:"
        echo "1) Chạy script"
        echo "2) Xem nhật ký"
        echo "3) Khởi động lại Node"
        echo "4) Xóa dữ liệu cũ"
        echo "5) Thoát"
        
        read -p "Nhập lựa chọn [1-5]: " lua_chon
        
        case $lua_chon in
            1)
                chay_script
                ;;
            2)
                xem_nhat_ky
                ;;
            3)
                khoi_dong_lai_node
                ;;
            4)
                xoa_du_lieu_cu
                ;;
            5)
                echo "Thoát script."
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ, vui lòng nhập lại."
                ;;
        esac
    done
}

# Hàm chạy script
function chay_script() {
    # Tải xuống tệp executor nếu chưa có
    if [ -f "executor-linux-v0.26.0.tar.gz" ]; then
        echo "Tệp executor-linux-v0.26.0.tar.gz đã tồn tại, bỏ qua bước tải xuống."
    else
        echo "Đang tải xuống executor-linux-v0.26.0.tar.gz..."
        wget https://github.com/t3rn/executor-release/releases/download/v0.26.0/executor-linux-v0.26.0.tar.gz

        if [ $? -ne 0 ]; then
            echo "Tải xuống thất bại, vui lòng kiểm tra kết nối mạng hoặc đường dẫn."
            exit 1
        fi

        echo "Giải nén tệp..."
        tar -xvzf executor-linux-v0.26.0.tar.gz

        if [ $? -ne 0 ]; then
            echo "Giải nén thất bại, vui lòng kiểm tra tệp tin."
            exit 1
        fi
    fi

    # Kiểm tra nếu thư mục hoặc tệp chứa "executor" tồn tại
    if ls | grep -q 'executor'; then
        echo "Đã tìm thấy tệp/thư mục chứa 'executor'."
    else
        echo "Không tìm thấy tệp/thư mục chứa 'executor', kiểm tra lại nội dung."
        exit 1
    fi

    # Cài đặt biến môi trường
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'

    # Nhập khóa riêng từ người dùng
    read -s -p "Nhập giá trị của PRIVATE_KEY_LOCAL (ẩn ký tự): " PRIVATE_KEY_LOCAL
    echo
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # Xóa tệp tin nén
    echo "Xóa tệp nén..."
    rm executor-linux-v0.26.0.tar.gz

    # Chuyển đến thư mục và chạy executor
    echo "Chuyển đến thư mục executor và chạy tệp..."
    cd ~/executor/executor/bin

    # Sử dụng pm2 để chạy executor
    pm2 start ./executor --name executor --log "$FILE_NHAT_KY" \
        --env NODE_ENV=$NODE_ENV \
        --env LOG_LEVEL=$LOG_LEVEL \
        --env LOG_PRETTY=$LOG_PRETTY \
        --env ENABLED_NETWORKS=$ENABLED_NETWORKS \
        --env PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    pm2 list
    echo "Executor đã được khởi chạy."

    read -n 1 -s -r -p "Nhấn phím bất kỳ để quay lại menu chính..."
    menu_chinh
}

# Hàm xem nhật ký
function xem_nhat_ky() {
    pm2 logs executor
    read -n 1 -s -r -p "Nhấn phím bất kỳ để quay lại menu chính..."
    menu_chinh
}

# Hàm xóa dữ liệu cũ
function xoa_du_lieu_cu() {
    THU_MUC_EXECUTOR="$HOME/executor"

    if [ -d "$THU_MUC_EXECUTOR" ]; then
        echo "Đã tìm thấy thư mục: $THU_MUC_EXECUTOR"
        echo "Đang xóa thư mục..."
        rm -rf "$THU_MUC_EXECUTOR"
        echo "Thư mục đã được xóa."
    else
        echo "Không tìm thấy thư mục: $THU_MUC_EXECUTOR"
    fi

    read -n 1 -s -r -p "Nhấn phím bất kỳ để quay lại menu chính..."
    menu_chinh
}

# Hàm khởi động lại Node
function khoi_dong_lai_node() {
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'

    read -s -p "Nhập giá trị của PRIVATE_KEY_LOCAL (ẩn ký tự): " PRIVATE_KEY_LOCAL
    echo
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    cd ~/executor/executor/bin

    pm2 restart executor
    pm2 list

    echo "Node đã được khởi động lại."
    read -n 1 -s -r -p "Nhấn phím bất kỳ để quay lại menu chính..."
    menu_chinh
}

# Khởi động menu chính
menu_chinh
