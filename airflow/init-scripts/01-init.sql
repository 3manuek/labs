-- Create a sample database for application data
CREATE DATABASE sample_data;

-- Connect to the sample database
\c sample_data

-- Create a users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Create an orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    shipping_address TEXT
);

-- Create a products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create an order_items table (junction table)
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);

-- Insert sample users
INSERT INTO users (username, email, full_name, last_login) VALUES
    ('john_doe', 'john.doe@example.com', 'John Doe', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('jane_smith', 'jane.smith@example.com', 'Jane Smith', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('bob_wilson', 'bob.wilson@example.com', 'Bob Wilson', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
    ('alice_johnson', 'alice.johnson@example.com', 'Alice Johnson', CURRENT_TIMESTAMP - INTERVAL '3 days'),
    ('charlie_brown', 'charlie.brown@example.com', 'Charlie Brown', CURRENT_TIMESTAMP - INTERVAL '12 hours');

-- Insert sample products
INSERT INTO products (product_name, description, price, stock_quantity, category) VALUES
    ('Laptop Pro 15', 'High-performance laptop with 15-inch display', 1299.99, 50, 'Electronics'),
    ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 29.99, 200, 'Electronics'),
    ('USB-C Cable', 'Premium USB-C charging cable, 6ft', 19.99, 500, 'Accessories'),
    ('Notebook Set', 'Set of 3 premium notebooks', 24.99, 150, 'Stationery'),
    ('Desk Lamp', 'LED desk lamp with adjustable brightness', 49.99, 75, 'Furniture'),
    ('Coffee Maker', 'Programmable coffee maker with thermal carafe', 89.99, 30, 'Appliances'),
    ('Headphones Pro', 'Noise-cancelling over-ear headphones', 299.99, 100, 'Electronics'),
    ('Water Bottle', 'Insulated stainless steel water bottle, 32oz', 34.99, 250, 'Accessories'),
    ('Backpack', 'Durable laptop backpack with multiple compartments', 79.99, 80, 'Accessories'),
    ('Keyboard Mechanical', 'RGB mechanical keyboard with cherry switches', 149.99, 60, 'Electronics');

-- Insert sample orders
INSERT INTO orders (user_id, total_amount, status, shipping_address) VALUES
    (1, 1349.98, 'completed', '123 Main St, New York, NY 10001'),
    (2, 329.98, 'shipped', '456 Oak Ave, Los Angeles, CA 90001'),
    (3, 89.99, 'pending', '789 Pine Rd, Chicago, IL 60601'),
    (1, 104.98, 'completed', '123 Main St, New York, NY 10001'),
    (4, 449.98, 'processing', '321 Elm St, Houston, TX 77001'),
    (5, 54.98, 'completed', '654 Maple Dr, Phoenix, AZ 85001'),
    (2, 1599.97, 'shipped', '456 Oak Ave, Los Angeles, CA 90001'),
    (3, 179.98, 'completed', '789 Pine Rd, Chicago, IL 60601');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    -- Order 1
    (1, 1, 1, 1299.99),
    (1, 3, 2, 19.99),
    (1, 2, 1, 29.99),
    -- Order 2
    (2, 7, 1, 299.99),
    (2, 2, 1, 29.99),
    -- Order 3
    (3, 6, 1, 89.99),
    -- Order 4
    (4, 5, 2, 49.99),
    (4, 4, 1, 24.99),
    -- Order 5
    (5, 10, 3, 149.99),
    -- Order 6
    (6, 8, 1, 34.99),
    (6, 3, 1, 19.99),
    -- Order 7
    (7, 1, 1, 1299.99),
    (7, 7, 1, 299.99),
    -- Order 8
    (8, 9, 2, 79.99),
    (8, 4, 1, 24.99);

-- Create some useful views
CREATE VIEW order_summary AS
SELECT
    o.order_id,
    u.username,
    u.email,
    o.order_date,
    o.total_amount,
    o.status,
    COUNT(oi.order_item_id) as item_count
FROM orders o
JOIN users u ON o.user_id = u.user_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, u.username, u.email, o.order_date, o.total_amount, o.status
ORDER BY o.order_date DESC;

CREATE VIEW product_sales AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) as total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY total_revenue DESC;

-- Create an index for better query performance
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Print summary
SELECT 'Database initialization complete!' as status;
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as order_count FROM orders;
SELECT COUNT(*) as order_items_count FROM order_items;
