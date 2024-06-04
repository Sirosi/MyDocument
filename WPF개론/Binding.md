# 이력
- 2024年06月04日(火) - 최초작성

# WPF Binding

바인딩에 대한 방법만 서술하겠다.

WPF는 기본적으로 Property와 Control(GUI 요소)간의 Binding이 아주 용이한 구조로 되어있다.

- **바인딩이란?**
    - UI와 Data를 연결하는 것.

## 주의점

사용 중, 문제가 생길 수 있는 부분들을 기재하겠다.

- x:Name과 Name은 WPF 내부에서 작동하는 방법이 다름.

## Binding 방법

### XAML 분해

**xaml 내 Binding**
``` xml
<TextBox>
    <TextBox.Text>
        <Binding Path="Title" ElementName="WindowName"/>
    </TextBox.Text>
</TextBox>
<!--상하 결과 동일-->
<TextBox Text="{Binding Title, ElementName=WindowName}"/>
<!--상하 결과 동일-->
<TextBox Text="{Binding Path=Title, ElementName=WindowName}"/>
```

**ViewModel과 Binding**
```xml
<TextBox>
    <TextBox.Text>
        <Binding Path="Title"/>
    </TextBox.Text>
</TextBox>
<!--상하 결과 동일-->
<TextBox Text="{Binding Title}"/>
<!--상하 결과 동일-->
<TextBox Text="{Binding Path=Title}"/>
```

WPF에서 GUI의 요소의 Option은 한 줄로 정의할 수도, 아니면 자식 태그를 늘리는 식으로 만들 수도 있다.

기본적으로 Binding할 때, Binding 이후에 옵션명이 안 들어가고 값만 덜렁있으면, Path의 값으로 인식한다.\
StaticResource등도 동일.

**※ 중괄호({, })를 사용하는 방법에 대한 별도 명칭이 존재하는지는 모르겠다.**

## DataContext 사용

**.xaml**
``` xml
<Label Content="{Binding Proto, Mode=OneWay, UpdateSourceTrigger=PropertyChanged}"/>
```

**ViewModel.cs**
``` csharp
public string Proto
{
    get => _proto;
    set => SetProperty(ref _proto, value);
}
private string _proto;
```

DataContext에 지정된 ViewModel의 Property와 Binding하는 방법이다.

Mode, UpdateSourceTrigger등의 Option은 후술.



## GUI 내

**.xaml**
```xml
<Button
    x:Name="button"
    Width="100" Height="50"
    />
<TextBox
    Width="{Binding Path=Width, ElementName=button}"
    Height="{Binding Path=Height, ElementName=button}"
    />
```

위와 같이 하면, TextBox는 button이란 이름을 가진 Button과 동일한 크기가 된다.

ElementName을 지정하면, 같은 xaml파일 내 Control의 Property값을 Binding할 수 있다.


## Binding 대상

### Binding

Property의 값과 Binding하겠다는 의미.

<br/>

### StaticResource

상위 GUI요소의 Resources에 정의한 Resource의 고정된 값을 Binding하겠다는 의미.

<br/>

### DynamicResource

상위 GUI요소의 Resources에 정의한 Resource의 변경될 수 있는 값을 Binding하겠다는 의미.

변경되면, Binding처럼 갱신됨.

<br/>

### x:Static



## Binding Option

### Path

바인딩할 값을 정의한다.

생략 가능.

<br/>

### ElementName

바인딩을 할 요소를 정의한다.

ElementName을 정의하지 않으면, DataContext로 지정된 ViewModel이라고 정의한다.

<br/>

### Mode

바인딩 모드를 정의한다.

- 바인딩 모드는 바인딩 구문에 **Mode=** 를 추가해서 지정한다.
- **OneWay:** Property -> View 단방향만 동기화
- **TwoWay:** Property <-> View 양방향 동기화
- **OneWayToSource:** Property <- View 단방향만 동기화
- **OneTime:** Property -> View 단방향으로 단 1회 동기화
- **Default:** View에서 수정이 가능하면 **TwoWay**가, View에서 수정이 불가능하면 **OneWay**가 된다.

<br/>

### UpdateSourceTrigger

갱신 트리거를 정의한다.

- **PropertyChanged:** 바인딩 대상이 갱신될 때마다 업데이트.
- **LostFocus:** 바인딩 대상인 View가 Focus를 잃을 때마다 업데이트.
- **Explicit:** _UpdateSource()_ Method를 호출할 때마다 업데이트.
    - ex)
        ``` csharp
        textBox.GetBindingExpression(TextBox.TextProperty).UpdateSource();
        ```
- **Default:** Text속성의 기본값은 **LostFoucs**가, 나머지 대부분은 **PropertyChanged**가 된다.

<br/>

### Convert

