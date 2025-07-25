# Image Requirements

## Category Frame Image

Replace `category_frame.png` with your actual frame image.

### Frame Requirements:
- **Format**: PNG with transparent background
- **Size**: Approximately 200x200 pixels (or as needed)
- **Background**: Transparent center area for content
- **Design**: Decorative border with red/beige pattern as shown in your reference

## Category Icons (Required Files)

You need to provide these 4 PNG images with transparent backgrounds:

### 1. `cleaning_icon.png`
- **For**: Cleaning category
- **Size**: 80x80 pixels (web) / 60x60 pixels (mobile)
- **Background**: Transparent

### 2. `home_cooking_icon.png`
- **For**: Home cooking category
- **Size**: 80x80 pixels (web) / 60x60 pixels (mobile)
- **Background**: Transparent

### 3. `babysitting_icon.png`
- **For**: Babysitting/Childcare category
- **Size**: 80x80 pixels (web) / 60x60 pixels (mobile)
- **Background**: Transparent

### 4. `elderly_care_icon.png`
- **For**: Elderly care category
- **Size**: 80x80 pixels (web) / 60x60 pixels (mobile)
- **Background**: Transparent

### Implementation Details:
- **Web**: 200x200 pixel containers with responsive icons (50% of container size)
- **Mobile**: 150x150 pixel containers with responsive icons (50% of container size)
- **Text Color**: Black (changed from red)
- **Background**: Uses website's base background (no additional background)
- **Frame**: Decorative border around each category (5% padding from edges)
- **Responsive**: Icons and text automatically scale to fit within frame boundaries
- **Overflow Protection**: Text has maxLines: 2 and overflow: TextOverflow.ellipsis

## Popular Services Frames (Required Files)

You need to provide these 3 PNG images with transparent backgrounds for the popular services section:

### 1. `service_frame_rectangle.png`
- **For**: Large screens (width > 1200px) - ALL 3 services
- **Shape**: Horizontal rectangle with rounded corners
- **Size**: Approximately 400x320 pixels (or as needed)
- **Background**: Transparent center area for content
- **Design**: Red and beige decorative pattern border

### 2. `service_frame_square.png`
- **For**: Medium screens (800px < width ≤ 1200px) - ALL 3 services
- **Shape**: Square with rounded corners
- **Size**: Approximately 320x320 pixels (or as needed)
- **Background**: Transparent center area for content
- **Design**: Red and beige decorative pattern border

### 3. `service_frame_vertical.png`
- **For**: Small screens (width ≤ 800px) - ALL 3 services
- **Shape**: Vertical rectangle with rounded corners
- **Size**: Approximately 320x400 pixels (or as needed)
- **Background**: Transparent center area for content
- **Design**: Red and beige decorative pattern border

### Popular Services Implementation:
- **Web**: ALL 3 services use the SAME frame type based on screen width
  - **Large Screens (>1200px)**: All services use rectangle frames
  - **Medium Screens (800-1200px)**: All services use square frames
  - **Small Screens (<800px)**: All services use vertical frames
- **Mobile**: ALL 3 services use rectangular frames in three rows for ALL screen sizes
  - **All Mobile Sizes**: All services use rectangular frames in vertical column (120px height, full width)
  - **Layout**: Three rows, one service per row, with 16px spacing between rows
- **Content**: Service icons, name, rating, and reviews inside the frame
- **Frame Padding**: 3% with min/max limits to prevent overflow
- **Background**: Uses website's base background (no additional background)
- **Overflow Protection**: All elements have clamp limits to prevent overflow

## Popular Services Icons (Required Files)

You need to provide these 3 PNG icons with transparent backgrounds for the popular services section:

### 1. `cleaning_popular_service.png`
- **For**: House Cleaning service
- **Design**: Vacuum cleaner icon (red and dark gray)
- **Size**: Approximately 80x80 pixels (or as needed)
- **Background**: Transparent
- **Style**: Flat design, minimalist

### 2. `traditional_dishes_popular_service.png`
- **For**: Traditional Dishes service
- **Design**: Grape leaves/dolma icon
- **Size**: Approximately 80x80 pixels (or as needed)
- **Background**: Transparent
- **Style**: Food presentation style

### 3. `apartment_setup_popular_service.png`
- **For**: Apartment Setup service
- **Design**: Multi-story building icon (red and dark gray)
- **Size**: Approximately 80x80 pixels (or as needed)
- **Background**: Transparent
- **Style**: Flat design, minimalist

### Popular Services Icons Implementation:
- **Web**: Icons scale to 40% of container width with responsive sizing
- **Mobile**: Icons scale to 35% of container width with responsive sizing
- **Responsive**: Icons automatically scale with frame size changes
- **Text Color**: Black for service names
- **Background**: Uses website's base background (no additional background) 