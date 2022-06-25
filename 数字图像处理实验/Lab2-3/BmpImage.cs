using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Media.Imaging;

namespace HistDemoA
{
    public class BmpImage
    {
        public class BmpInfo
        {
            public string BmpMark { get; set; }
            public int FileSize { get; set; }
            public int Reserved { get; set; }
            public int BitmapDataOffset { get; set; }
            public int BitmapHeaderSize { get; set; }
            public int Width { get; set; }
            public int Height { get; set; }
            public int Planes { get; set; }
            /* 
                每个像素的位数 
                1 - 单色位图
                4 - 16 色位图 
                8 - 256 色位图 
                16 - 16bit 高彩色位图 
                24 - 24bit 真彩色位图 
                32 - 32bit 增强型真彩色位图 
            */
            public int BitsPerPixel { get; set; }
            public int Compression { get; set; }
            public int BitmapDataSize { get; set; }
            public int HResolution { get; set; }
            public int VResolution { get; set; }
            public int Colors { get; set; }
            public int ImportantColors { get; set; }
            public List<byte> Palette { get; set; }
            public List<byte> BitmapData { get; set; }
        }

        public static BmpInfo Parse(byte[] bmpBytes)
        {
            BmpInfo bmpInfo = new BmpInfo
            {
                BmpMark = bmpBytes.ToStringEx(0, 2),        // bmp 标识
                FileSize = bmpBytes.ToInt32(2, 4),          // 整个文件的大小
                Reserved = bmpBytes.ToInt32(6, 4),          // 保留字
                BitmapDataOffset = bmpBytes.ToInt32(10, 4), // 获取从文件开始到位图数据开始之间的偏移量
                BitmapHeaderSize = bmpBytes.ToInt32(14, 4), // 位图信息头(Bitmap Info Header)的长度
                Width = bmpBytes.ToInt32(18, 4),            // 位图的宽度，以象素为单位
                Height = bmpBytes.ToInt32(22, 4),           // 位图的高度，以象素为单位
                Planes = bmpBytes.ToInt32(26, 2),           // 位图的位面数，恒为1
                BitsPerPixel = bmpBytes.ToInt32(28, 2),     // 像素位数
                Compression = bmpBytes.ToInt32(30, 4),      // 压缩与否
                BitmapDataSize = bmpBytes.ToInt32(34, 4),   // 位图数据大小
                HResolution = bmpBytes.ToInt32(38, 4),      // 水平分辨率
                VResolution = bmpBytes.ToInt32(42, 4),      // 垂直分辨率
                Colors = bmpBytes.ToInt32(46, 4),           // 位图使用的颜色数
                ImportantColors = bmpBytes.ToInt32(50, 4)   // 指定重要的颜色数
            };
            bmpInfo.BitmapData = bmpBytes.ToBytesList(
                bmpInfo.BitmapDataOffset, 
                bmpInfo.FileSize - bmpInfo.BitmapDataOffset
            );
            bmpInfo.Palette = bmpBytes.ToBytesList(54, bmpInfo.BitmapDataOffset - 54);
            return bmpInfo;
        }

        // byte[] 转换为 BitmapImage
        public BitmapImage ByteArrayToBitmapImage(byte[] byteArray)
        {
            BitmapImage bmp;
            try
            {
                bmp = new BitmapImage();
                bmp.BeginInit();
                bmp.StreamSource = new MemoryStream(byteArray);
                bmp.EndInit();
            }
            catch
            {
                bmp = null;
            }
            return bmp;
        }
    }

    public static class BytesEntend
    {
        public static int ToInt32(this byte[] bytes, int index, int count)
        {
            int result = 0;
            for (int i = count - 1; i >= 0; i--)
            {
                if (bytes[index + i] != 0)
                {
                    result += (int)Math.Pow(256, i) * bytes[index + i];
                }
            }

            return result;
        }

        public static string ToStringEx(this byte[] bytes, int index, int count)
        {
            return Encoding.Default.GetString(bytes, index, count);
        }

        public static List<byte> ToBytesList(this byte[] bytes, int index, int count)
        {
            return bytes.Skip(index).Take(count).ToList();
        }
    }
}
