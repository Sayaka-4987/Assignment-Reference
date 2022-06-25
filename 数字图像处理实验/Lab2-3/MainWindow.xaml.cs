using System.Windows;

namespace HistDemoA
{
    /// <summary>
    /// MainWindow.xaml 的交互逻辑
    /// </summary>
    public partial class MainWindow : Window
    {
        private ViewModel viewModel;

        public MainWindow()
        {
            InitializeComponent();
            viewModel = new ViewModel();
            DataContext = viewModel;
        }

        private void Button_Open_Click(object sender, RoutedEventArgs e)
        {
            viewModel.FileFullPath = viewModel.OpenBMPFile();
        }

        private void Button_Histogram_Equalization_Click(object sender, RoutedEventArgs e)
        {
            viewModel.AfterFileFullPath = viewModel.HistogramEqualization();
        }

        private void Button_Mean_Filtering_Click(object sender, RoutedEventArgs e)
        {
            viewModel.AfterFileFullPath = viewModel.MeanFilter();
        }

        private void Button_Median_Filtering_Click(object sender, RoutedEventArgs e)
        {
            viewModel.AfterFileFullPath = viewModel.MedianFilter();
        }

        private void Button_Quit_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
