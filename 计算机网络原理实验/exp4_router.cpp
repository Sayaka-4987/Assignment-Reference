#include <queue>
#include <vector>
#include <iostream>
#define INF 0xFFFFFF
#define MAX_NODE_NUM 110

/*
5 6
1 2 3
2 3 4
3 4 5
4 5 7
5 2 1
3 5 2

*/

int n;
int w[MAX_NODE_NUM][MAX_NODE_NUM];

using namespace std;

struct node {
    int id;
    int weight;
};

auto cmp = [](node a, node b) { return a.weight > b.weight; };
priority_queue<node, vector<node>, decltype(cmp) > q(cmp);     // 优先队列，这里是升序队列

int parent[MAX_NODE_NUM];
bool visited[MAX_NODE_NUM];
node d[MAX_NODE_NUM];

void Dijkstra(int s) {
    for(int i = 1; i <= n; i++) {
        d[i].id = i;
        d[i].weight = INF;
        parent[i] = -1;
        visited[i] = false;
    }

    d[s].weight = 0;
    q.push(d[s]);
    while(!q.empty()) {
        node cd = q.top();
        q.pop();
        int u = cd.id;
        if(visited[u])  continue;

        visited[u] = true;
        for(int v = 1; v <= n; v++) {
            if(v != u && !visited[v] && d[v].weight > d[u].weight+w[u][v]) {
                d[v].weight = d[u].weight + w[u][v];
                parent[v] = u;
                q.push(d[v]);
            }
        }
    }
}

int main() {
    int m, a, b, c, st, ed;
    cout << "请输入顶点数和边数: " << endl;
    cin >> n >> m;
    cout << "请依次输入边以及权值，格式为(起点, 终点, 权重值)，下标从 0 开始，默认为无向图: " << endl;
    for(auto i = 1; i <= n; i++) {
        for(auto j = i; j <= n; j++) {
            w[i][j] = w[j][i] = INF;
        }
    }

    while(m--) {
        cin >> a >> b >> c;
        if(w[a][b] > c)  w[a][b]= w[b][a] = c;
    }

    cout << "请输入起点和终点: " << endl;
    cin >> st >> ed;

    Dijkstra(st);

    if(d[ed].weight != INF)
        cout << "最短路径权值为: " << d[ed].weight << endl;
    else
        cout << "不存在从顶点" << st << "到顶点" << ed << "的最短路径! " << endl;

    return 0;
}