#!/bin/zsh

# ===== backup.sh =====

# 1. 날짜 변수 생성
DATE=$(date +"%Y%m%d")

# 2. 백업 디렉토리 이름
BACKUP_DIR="backup_$DATE"

# 3. 대상 디렉토리
TARGET_DIR="src"

# 4. 로그 파일
LOG_FILE="backup.log"

echo "==== BACKUP START: $DATE ====" >> $LOG_FILE

# 5. 백업 디렉토리 생성
mkdir -p $BACKUP_DIR
echo "Created directory: $BACKUP_DIR" >> $LOG_FILE

# 6. 복사
if [ -d "$TARGET_DIR" ]; then
  cp -r $TARGET_DIR $BACKUP_DIR
  echo "Copied $TARGET_DIR to $BACKUP_DIR" >> $LOG_FILE
else
  echo "Target directory $TARGET_DIR not found!" >> $LOG_FILE
fi

echo "==== BACKUP END ====" >> $LOG_FILE
