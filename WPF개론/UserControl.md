# 이력

- 2024年05月30日(木) - 최초작성


# UserControl 시작

> ※ .NET8 및 WPF을 기준으로 서술됨.

UserControl(이하 UC)은 WPF 및 WinForm등에서 지원하는 말그대로, User(개발자)가 만들어서 사용하는 Control(WPF/WinForm에서 사용되는 UI 요소)이다.

## 용도

- UC를 MDI 구조를 구성할 때, Child로 사용하는 경우도 있다.
    - ※ MDI 구조란, ParentWindow라는 파일 내부에 별도의 파일로 지정된 ChildView가 표출되는 형태로, 공통 부분을 제외하고 내부 페이지 별로 나눠서 개발하기 위해 주로 사용되는 구조를 의미.
    - ※ Page로 구성하는 경우도 있지만, UC로 하는 걸 더 권장하는 경향이 있는 듯하다.
- 자주 사용하는 복잡한 구조의 UI를 그룹화해서, XAML 파일의 길이를 줄이기 위해서.



# UserControl Paging

