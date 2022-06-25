using CommunityToolkit.Mvvm.ComponentModel;
using Microsoft.Win32;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using static HistDemoA.BmpImage;
using System;

namespace HistDemoA
{
    public class ViewModel : ObservableRecipient
    {
        // 默认图片路径
        private const string image_invalid = @"pack://application:,,,/HistDemoA;component/Properties/image_invalid.bmp";
        private const string image_empty = @"pack://application:,,,/HistDemoA;component/Properties/image_empty.bmp";

        // 运行时使其他功能按钮失效
        private bool isNotRunning = true;
        public bool IsNotRunning { get => isNotRunning; set => SetProperty(ref isNotRunning, value); }

        // 标记当前是否有已经打开的 bmp 文件，防止 Image 组件路径错误导致程序崩溃
        private bool hasVaildBMP = false;
        public bool HasVaildBMP { get => hasVaildBMP; set => SetProperty(ref hasVaildBMP, value); }

        // 标记当前运算是否已经完成
        private bool hasFinishImage = false;
        public bool HasFinishBalance { get => hasFinishImage; set => SetProperty(ref hasFinishImage, value); }

        // 位图原文件的完整路径
        private string fileFullPath = "";
        public string FileFullPath
        {
            get => hasVaildBMP ? fileFullPath : image_invalid;
            set => SetProperty(ref fileFullPath, value);
        }

        // 存放位图信息流
        private BmpInfo bmpArray = null;
        // 暂时存放待修改的位图
        private Bitmap bitmapBefore = null;
        // 默认保存路径
        // private const string defaultSavePath = @"D:/";

        // 处理后图像的路径
        public string afterFileFullPath = "";
        public string AfterFileFullPath
        {
            get => hasFinishImage ? afterFileFullPath : image_empty;
            set => SetProperty(ref afterFileFullPath, value);
        }

        // 打开 bmp 文件
        public string OpenBMPFile()
        {
            isNotRunning = false;   // 使功能按钮失效，信息清除
            bmpArray = null;
            bitmapBefore = null;
            afterFileFullPath = "";
            OpenFileDialog ofd = new OpenFileDialog
            {
                Filter = "位图文件(*.bmp)|*.bmp|所有文件|*.*",  // 文件类型过滤器
                ValidateNames = true,       // 验证用户输入是否是一个有效的 Windows 文件名
                CheckFileExists = true,     // 验证路径的有效性
                CheckPathExists = true      // 验证路径的有效性
            };

            string strFileName;
            if (ofd.ShowDialog() == true) strFileName = ofd.FileName;   // 用户点击确认按钮时获取文件路径字符串
            else return "";

            Stream stream = File.OpenRead(strFileName); // 打开位图文件
            byte[] buffer = new byte[stream.Length];    // 缓冲区
            stream.Read(buffer, 0, buffer.Length);      // 读入数据流
            bmpArray = Parse(buffer);                   // 保存到 bmp 结构数组中
            bitmapBefore = new Bitmap(stream);
            isNotRunning = true;                        // 使功能按钮生效，标记已经返回的值
            hasVaildBMP = true;
            hasFinishImage = false;
            return strFileName;
        }

        // 生成输出文件名
        public string GenerateOutputFilename(string tag)
        {
            string filename = Path.GetFileName(FileFullPath);           // 获取原图的文件名和路径
            string fileSavePath = Path.GetDirectoryName(FileFullPath) + @"\";
            // 输出图片名的规律
            // 直方图均衡：balance_原文件名.bmp
            // 中值滤波：  median(1)_原文件名.bmp
            // 均值滤波：  mean(2)_原文件名.bmp
            string newFullPath = fileSavePath + tag + "_" + filename;
            int times = 1;
            while (File.Exists(newFullPath))   // 直接删同名文件会闪退，所以遇到重名文件就循环建新名称
            {
                newFullPath = fileSavePath + tag + "(" + times++ + ")_" + filename;
            }
            return newFullPath;     // 返回文件名
        }

        // 直方图均衡函数
        public string HistogramEqualization()
        {
            isNotRunning = false;
            hasFinishImage = false;
            Bitmap src = bitmapBefore;
            if (src == null)    // 找不到源文件就直接返回
            {
                isNotRunning = true;
                return "";
            }

            Bitmap res = new Bitmap(src);

            int[] histogramArrayR = new int[256];   // 各个灰度级的像素数 R
            int[] histogramArrayG = new int[256];   // 各个灰度级的像素数 G
            int[] histogramArrayB = new int[256];   // 各个灰度级的像素数 B
            int[] tempArrayR = new int[256];
            int[] tempArrayG = new int[256];
            int[] tempArrayB = new int[256];
            byte[] pixelMapR = new byte[256];
            byte[] pixelMapG = new byte[256];
            byte[] pixelMapB = new byte[256];

            Rectangle rt = new Rectangle(0, 0, src.Width, src.Height);
            BitmapData bmpData = res.LockBits(rt, ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb);
            unsafe
            {
                for (int i = 0; i < bmpData.Height; i++)    // 统计各个灰度级的像素个数
                {
                    byte* ptr = (byte*)bmpData.Scan0 + i * bmpData.Stride;
                    for (int j = 0; j < bmpData.Width; j++)
                    {
                        histogramArrayB[*(ptr + j * 3)]++;
                        histogramArrayG[*(ptr + j * 3 + 1)]++;
                        histogramArrayR[*(ptr + j * 3 + 2)]++;
                    }
                }

                for (int i = 0; i < 256; i++)   // 计算各个灰度级的累计分布函数
                {
                    if (i != 0)
                    {
                        tempArrayB[i] = tempArrayB[i - 1] + histogramArrayB[i];
                        tempArrayG[i] = tempArrayG[i - 1] + histogramArrayG[i];
                        tempArrayR[i] = tempArrayR[i - 1] + histogramArrayR[i];
                    }
                    else
                    {
                        tempArrayB[0] = histogramArrayB[0];
                        tempArrayG[0] = histogramArrayG[0];
                        tempArrayR[0] = histogramArrayR[0];
                    }

                    pixelMapB[i] = (byte)(255.0 * tempArrayB[i] / (bmpData.Width * bmpData.Height) + 0.5);  // 计算累计概率函数，并将值放缩至 0~255 范围内
                    pixelMapG[i] = (byte)(255.0 * tempArrayG[i] / (bmpData.Width * bmpData.Height) + 0.5);
                    pixelMapR[i] = (byte)(255.0 * tempArrayR[i] / (bmpData.Width * bmpData.Height) + 0.5);
                }

                for (int i = 0; i < bmpData.Height; i++)    // 映射转换
                {
                    byte* ptr = (byte*)bmpData.Scan0 + i * bmpData.Stride;
                    for (int j = 0; j < bmpData.Width; j++)
                    {
                        *(ptr + j * 3) = pixelMapB[*(ptr + j * 3)];
                        *(ptr + j * 3 + 1) = pixelMapG[*(ptr + j * 3 + 1)];
                        *(ptr + j * 3 + 2) = pixelMapR[*(ptr + j * 3 + 2)];
                    }
                }
            }

            string newFullPath = GenerateOutputFilename("balance");   // 生成处理后的文件名

            res.UnlockBits(bmpData);    // 从内存中解锁数据
            res.Save(newFullPath);      // 保存处理后的图片
            res.Dispose();              // 释放占用的所有资源

            isNotRunning = true;
            hasFinishImage = true;
            return newFullPath;
        }

        // 中值滤波函数
        public string MedianFilter()
        {
            isNotRunning = false;
            hasFinishImage = false;
            Bitmap src = bitmapBefore;
            if (src == null)    // 找不到源文件就直接返回
            {
                isNotRunning = true;
                return "";
            }
            Bitmap res = new Bitmap(src);   // 存放滤波后的图像

            int[] dx = { -1, 0, 1, -1, 0, 1, -1, 0, 1 };
            int[] dy = { -1, -1, -1, 0, 0, 0, 1, 1, 1 };

            for (int j = 1; j < src.Height - 1; j++)   
            {
                for (int i = 1; i < src.Width - 1; i++)
                {
                    int[] pixelArrayB = new int[9]; // 遍历每个像素点
                    int[] pixelArrayG = new int[9];
                    int[] pixelArrayR = new int[9];
                    for (int k = 0; k < 9; k++)     // 对每个像素取它周围 8 个像素点和它本身
                    {
                        Color color = src.GetPixel(i + dx[k], j + dy[k]);
                        pixelArrayB[k] = color.B;
                        pixelArrayG[k] = color.G;
                        pixelArrayR[k] = color.R;
                    }
                    Array.Sort(pixelArrayB);        // 排序这 9 个像素点的 RGB 值
                    Array.Sort(pixelArrayG);
                    Array.Sort(pixelArrayR);
                    // 取 RGB 中值作为该像素点的颜色值
                    res.SetPixel(i, j, Color.FromArgb(pixelArrayR[4], pixelArrayG[4], pixelArrayB[4]));
                }
            }

            string newFullPath = GenerateOutputFilename("median");   // 生成处理后的文件名

            res.Save(newFullPath);      // 保存处理后的图片
            res.Dispose();              // 释放占用的所有资源

            isNotRunning = true;
            hasFinishImage = true;
            return newFullPath;
        }

        // 均值滤波函数
        public string MeanFilter()
        {
            isNotRunning = false;
            hasFinishImage = false;
            Bitmap src = bitmapBefore;
            if (src == null)    // 找不到源文件就直接返回
            {
                isNotRunning = true;
                return "";
            }
            Bitmap res = new Bitmap(src);   // 存放滤波后的图像

            int[] dx = { -1, 0, 1, -1, 0, 1, -1, 0, 1 };
            int[] dy = { -1, -1, -1, 0, 0, 0, 1, 1, 1 };

            for (int j = 1; j < src.Height - 1; j++)
            {
                for (int i = 1; i < src.Width - 1; i++)
                {
                    int pixelArraySumB = 0;
                    int pixelArraySumG = 0;
                    int pixelArraySumR = 0;
                    for (int k = 0; k < 9; k++)     // 对每个像素取它周围 8 个像素点和它本身
                    {
                        Color color = src.GetPixel(i + dx[k], j + dy[k]);
                        pixelArraySumB += color.B;
                        pixelArraySumG += color.G;
                        pixelArraySumR += color.R;
                    }
                    
                    // 取 RGB 均值作为该像素点的颜色值
                    res.SetPixel(i, j, 
                        Color.FromArgb(pixelArraySumR / 9, pixelArraySumG / 9, pixelArraySumB / 9));
                }
            }

            string newFullPath = GenerateOutputFilename("mean");   // 生成处理后的文件名

            res.Save(newFullPath);      // 保存处理后的图片
            res.Dispose();              // 释放占用的所有资源

            isNotRunning = true;
            hasFinishImage = true;
            return newFullPath;
        }
    }
}
