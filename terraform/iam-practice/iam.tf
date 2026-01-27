resource "aws_iam_user" "test_user" {
  name = "tf-test-user"
}

resource "aws_iam_policy" "s3_read_only" {
  name = "tf-s3-read-only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.demo.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.demo.arn}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.test_user.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

