package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOStorage struct {
	client *minio.Client
	bucket string
}

// NewMinIOStorage creates a new MinIO storage client
func NewMinIOStorage(endpoint, accessKey, secretKey, bucket, region string, useSSL bool) (*MinIOStorage, error) {
	// Initialize MinIO client
	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useSSL,
		Region: region,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create MinIO client: %w", err)
	}

	// Ensure bucket exists
	ctx := context.Background()
	exists, err := client.BucketExists(ctx, bucket)
	if err != nil {
		return nil, fmt.Errorf("failed to check bucket existence: %w", err)
	}

	if !exists {
		err = client.MakeBucket(ctx, bucket, minio.MakeBucketOptions{Region: region})
		if err != nil {
			return nil, fmt.Errorf("failed to create bucket: %w", err)
		}

		// Set bucket policy to public read
		policy := fmt.Sprintf(`{
			"Version": "2012-10-17",
			"Statement": [{
				"Effect": "Allow",
				"Principal": {"AWS": ["*"]},
				"Action": ["s3:GetObject"],
				"Resource": ["arn:aws:s3:::%s/*"]
			}]
		}`, bucket)

		if err := client.SetBucketPolicy(ctx, bucket, policy); err != nil {
			return nil, fmt.Errorf("failed to set bucket policy: %w", err)
		}
	}

	return &MinIOStorage{
		client: client,
		bucket: bucket,
	}, nil
}

// Put stores an object in MinIO
func (m *MinIOStorage) Put(ctx context.Context, objectKey string, data []byte, contentType string) error {
	_, err := m.client.PutObject(
		ctx,
		m.bucket,
		objectKey,
		bytes.NewReader(data),
		int64(len(data)),
		minio.PutObjectOptions{
			ContentType: contentType,
		},
	)
	return err
}

// Get retrieves an object from MinIO
func (m *MinIOStorage) Get(ctx context.Context, objectKey string) ([]byte, error) {
	obj, err := m.client.GetObject(ctx, m.bucket, objectKey, minio.GetObjectOptions{})
	if err != nil {
		return nil, err
	}
	defer obj.Close()

	data, err := io.ReadAll(obj)
	if err != nil {
		return nil, fmt.Errorf("failed to read object: %w", err)
	}

	return data, nil
}

// Exists checks if an object exists in MinIO
func (m *MinIOStorage) Exists(ctx context.Context, objectKey string) bool {
	_, err := m.client.StatObject(ctx, m.bucket, objectKey, minio.StatObjectOptions{})
	return err == nil
}

// Delete removes an object from MinIO
func (m *MinIOStorage) Delete(ctx context.Context, objectKey string) error {
	return m.client.RemoveObject(ctx, m.bucket, objectKey, minio.RemoveObjectOptions{})
}

// Ping checks if MinIO is accessible
func (m *MinIOStorage) Ping(ctx context.Context) error {
	_, err := m.client.BucketExists(ctx, m.bucket)
	return err
}

// GetURL returns a presigned URL for an object (for temporary access)
func (m *MinIOStorage) GetURL(ctx context.Context, objectKey string) (string, error) {
	url, err := m.client.PresignedGetObject(ctx, m.bucket, objectKey, 0, nil)
	if err != nil {
		return "", err
	}
	return url.String(), nil
}
