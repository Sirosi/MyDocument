# 스무스하게 움직이는 ProgressBar

## ViewModel에서 Control을 조작
``` xml
<!--View.xaml-->
<ProgressBar Width="300" Height="15"
             Maximum="{Binding ProgressMax}" Value="{Binding AnimProgress}"/>
```

``` csharp
// ViewModel.cs
private int _progressMax;
public int ProgressMax
{
    get => _progressMax;
    set => SetProperty(ref _progressMax, value);
} // 100이라고 가정

private float _currentProgress;
public float CurrentProgress
{
    get => _currentProgress;
    set => SetProperty(ref _currentProgress, value);
} // 0, 20, 80, 100순서로 변경된다고 가정

private float _animProgress;
public float AnimProgress
{
    get => _animProgress;
    set => SetProperty(ref _animProgress, value);
} // 초기값 0이라고 가정

// 몇 사이클이 돼야 0 -> ProgressMax가 될 수 있는지
private int stab = 100;
// 한 사이클의 딜레이 타임(ms)
private int progressDelay = 50;


private void SmoothProgressMethod()
{
    Thread thread = new(() =>
    {
        while (true)
        {
            if (AnimProgress != CurrentProgress)
            {
                float tempProgresss = AnimProgress;
                float tickProg = ProgressMax / stab;

                tempProgresss += AnimProgress < CurrentProgress ? tickProg : -tickProg;
                float disValue = AnimProgress < CurrentProgress ? CurrentProgress - AnimProgress : AnimProgress - CurrentProgress;
                if(disValue < tickProg)
                {
                    tempProgresss = CurrentProgress;
                }
                AnimProgress = tempProgresss;
            }
            Thread.Sleep(progressDelay);
        }
    })
    {
        IsBackground = true
    };
    thread.Start();
}
```